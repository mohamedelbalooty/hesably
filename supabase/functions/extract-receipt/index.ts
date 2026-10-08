import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { z } from "npm:zod";
import { GoogleGenAI } from "npm:@google/genai";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// Zod schema for the expected response
const extractionSchema = z.object({
  is_receipt: z.boolean(),
  transaction_type: z.enum(["income", "expense"]),
  date: z.string().nullable().optional(),
  total_amount: z.number().nullable().optional(),
  currency: z.string().nullable().optional(),
  vendor_customer_name: z.string().nullable().optional(),
  suggested_category: z.string().nullable().optional(),
  line_items: z.array(z.object({
    description: z.string(),
    quantity: z.number(),
    unit_price: z.number(),
    total_price: z.number()
  })).nullable().optional(),
  confidence_scores: z.object({
    overall: z.number(),
    date: z.number(),
    total_amount: z.number(),
    vendor_customer_name: z.number()
  })
});

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { receipt_image_path, business_id } = await req.json();

    if (!receipt_image_path || !business_id) {
      throw new Error('Missing receipt_image_path or business_id');
    }

    // Initialize Supabase client with the user's Auth context
    const authHeader = req.headers.get('Authorization')!;
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    );

    // Rate Limiting: Max 20 requests per minute per business
    const oneMinuteAgo = new Date(Date.now() - 60 * 1000).toISOString();
    const { count } = await supabase
      .from('ai_extractions')
      .select('*', { count: 'exact', head: true })
      .eq('business_id', business_id)
      .gte('created_at', oneMinuteAgo);

    if (count !== null && count >= 20) {
      return new Response(JSON.stringify({ error: 'Rate limit exceeded. Maximum 20 extractions per minute.' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 429,
      });
    }

    // Idempotency: Check if an extraction already succeeded for this receipt image
    const { data: existingExtraction } = await supabase
      .from('ai_extractions')
      .select('raw_response')
      .eq('business_id', business_id)
      .eq('receipt_image_path', receipt_image_path)
      .eq('status', 'success')
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (existingExtraction && existingExtraction.raw_response) {
      try {
        const validatedCached = extractionSchema.parse(existingExtraction.raw_response);
        return new Response(JSON.stringify(validatedCached), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json', 'X-Cache': 'HIT' },
          status: 200,
        });
      } catch {
        // If cached extraction fails schema, proceed to re-extract
      }
    }

    let raw_response: any = null;

    if (Deno.env.get('USE_MOCK_GEMINI') === 'true') {
      // Mocked simulation
      console.log('Using mocked Gemini response');
      await new Promise(resolve => setTimeout(resolve, 1500)); // Simulate delay
      raw_response = {
        is_receipt: true,
        transaction_type: "expense",
        date: "2026-08-27",
        total_amount: 1450.50,
        currency: "EGP",
        vendor_customer_name: "Tech Hub Solutions",
        suggested_category: "Office Supplies",
        line_items: [
          { description: "Wireless Keyboard", quantity: 1, unit_price: 800.00, total_price: 800.00 },
          { description: "Mousepad", quantity: 2, unit_price: 325.25, total_price: 650.50 }
        ],
        confidence_scores: {
          overall: 0.95,
          date: 0.98,
          total_amount: 0.99,
          vendor_customer_name: 0.85
        }
      };
    } else {
      // Download the image from Supabase Storage
      const { data: fileData, error: downloadError } = await supabase.storage
        .from('receipts')
        .download(receipt_image_path);

      if (downloadError) {
        throw new Error(`Failed to download image: ${downloadError.message}`);
      }

      const arrayBuffer = await fileData.arrayBuffer();
      const base64Image = btoa(String.fromCharCode(...new Uint8Array(arrayBuffer)));
      
      // Initialize Gemini
      const geminiApiKey = Deno.env.get('GEMINI_API_KEY');
      if (!geminiApiKey) {
        throw new Error('GEMINI_API_KEY is not set');
      }

      const ai = new GoogleGenAI({ apiKey: geminiApiKey });

      const SYSTEM_PROMPT_V1 = `
You are an expert AI assistant designed to extract structured data from receipts and invoices.
Your task is to analyze the provided image and extract the fields as defined in the JSON schema.
If the image is not a receipt, return is_receipt=false.
If fields are illegible, return them as null and reduce the confidence_scores.
Ensure total_amount equals the sum of line items if present.
Return strictly valid JSON.
`;

      const response = await ai.models.generateContent({
        model: 'gemini-3.5-flash',
        contents: [
          { role: 'user', parts: [
              { text: SYSTEM_PROMPT_V1 },
              { inlineData: { mimeType: 'image/jpeg', data: base64Image } }
          ] }
        ],
        config: {
          responseMimeType: "application/json",
          responseSchema: {
            type: "object",
            properties: {
              is_receipt: { type: "boolean" },
              transaction_type: { type: "string", enum: ["income", "expense"] },
              date: { type: "string", nullable: true },
              total_amount: { type: "number", nullable: true },
              currency: { type: "string", nullable: true },
              vendor_customer_name: { type: "string", nullable: true },
              suggested_category: { type: "string", nullable: true },
              line_items: {
                type: "array",
                items: {
                  type: "object",
                  properties: {
                    description: { type: "string" },
                    quantity: { type: "number" },
                    unit_price: { type: "number" },
                    total_price: { type: "number" }
                  }
                },
                nullable: true
              },
              confidence_scores: {
                type: "object",
                properties: {
                  overall: { type: "number" },
                  date: { type: "number" },
                  total_amount: { type: "number" },
                  vendor_customer_name: { type: "number" }
                }
              }
            },
            required: ["is_receipt", "transaction_type", "confidence_scores"]
          }
        }
      });

      const responseText = response.text;
      if (!responseText) {
          throw new Error('No text returned from Gemini API');
      }
      raw_response = JSON.parse(responseText);
    }

    // Validate the response
    const validatedData = extractionSchema.parse(raw_response);

    // Insert log into ai_extractions (status: success)
    const { error: insertError } = await supabase.from('ai_extractions').insert({
      business_id,
      receipt_image_path,
      raw_response: validatedData,
      status: 'success'
    });

    if (insertError) {
      console.error('Failed to log extraction to database:', insertError);
      // We still return the data to the client even if logging fails, to not block the user flow
    }

    return new Response(JSON.stringify(validatedData), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });

  } catch (error) {
    console.error('Error during extraction:', error);
    
    // Attempt to log the failure if we have enough context
    try {
      const reqClone = await req.clone().json();
      const authHeader = req.headers.get('Authorization')!;
      if (reqClone.business_id && reqClone.receipt_image_path && authHeader) {
        const supabase = createClient(
          Deno.env.get('SUPABASE_URL') ?? '',
          Deno.env.get('SUPABASE_ANON_KEY') ?? '',
          { global: { headers: { Authorization: authHeader } } }
        );
        await supabase.from('ai_extractions').insert({
          business_id: reqClone.business_id,
          receipt_image_path: reqClone.receipt_image_path,
          raw_response: { error: (error as Error).message },
          status: 'failure'
        });
      }
    } catch (e) {
      // Ignore failure to log failure
    }

    return new Response(JSON.stringify({ error: (error as Error).message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    });
  }
});
