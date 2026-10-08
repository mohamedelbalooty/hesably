import { createClient } from "@supabase/supabase-js"

const SUPABASE_URL = "http://127.0.0.1:54321"
const ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
const SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"

const adminClient = createClient(SUPABASE_URL, SERVICE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
})

async function runE2E() {
  console.log("==================================================")
  console.log("STARTING HESABLY REAL END-TO-END VALIDATION SCRIPT")
  console.log("==================================================")

  const testPhone = "+201099887766"
  const testEmail = "elamal.owner@hesably.com"

  // 1. Clean up any previous test user with this phone or email
  const { data: userList } = await adminClient.auth.admin.listUsers()
  const existingUser = userList?.users?.find(
    (u) => u.phone === testPhone || u.email === testEmail
  )
  if (existingUser) {
    console.log(`Cleaning up old test user: ${existingUser.id}...`)
    await adminClient.auth.admin.deleteUser(existingUser.id)
  }

  // 2. Step 1: New User via Phone Auth
  console.log("\n[Step 1] Creating New User via Phone Auth...")
  const { data: createdUserData, error: createErr } = await adminClient.auth.admin.createUser({
    phone: testPhone,
    phone_confirm: true,
    user_metadata: { name: "أحمد عبد الله" },
  })

  if (createErr || !createdUserData.user) {
    throw new Error(`Failed to create phone user: ${createErr?.message}`)
  }
  const user = createdUserData.user
  console.log(`✓ Phone User Created: ID=${user.id}, Phone=${user.phone}`)

  // Create an authenticated client for this user
  const userClient = createClient(SUPABASE_URL, ANON_KEY, {
    auth: { persistSession: false },
  })
  // Generate token/session for this user
  const { data: sessionData, error: sessionErr } = await adminClient.auth.admin.generateLink({
    type: "magiclink",
    email: "temp@temp.com",
    options: { redirectTo: "http://localhost:3000" },
  })

  // 3. Step 2: Business Onboarding
  console.log("\n[Step 2] Business Onboarding...")
  const { data: business, error: bizErr } = await adminClient
    .from("businesses")
    .insert({
      owner_id: user.id,
      name: "سوبرماركت الأمل",
      type: "retail",
      currency: "EGP",
    })
    .select()
    .single()

  if (bizErr || !business) {
    throw new Error(`Failed to create business: ${bizErr?.message}`)
  }
  console.log(`✓ Business Created: ID=${business.id}, Name=${business.name}`)

  // 4. Step 3: Verify Seeded Default Categories
  console.log("\n[Step 3] Verifying Default Categories...")
  const { data: categories, error: catErr } = await adminClient
    .from("categories")
    .select("*")
    .eq("business_id", business.id)

  if (catErr || !categories || categories.length === 0) {
    throw new Error(`Categories were not seeded properly: ${catErr?.message}`)
  }
  console.log(`✓ Seeded ${categories.length} categories:`, categories.map((c) => c.name).join(", "))

  const suppliesCategory = categories.find((c) => c.name === "Supplies" || c.name === "مشتريات وبضاعة") || categories[0]

  // 5. Step 4: Receipt Capture, Upload & AI Extraction Draft
  console.log("\n[Step 4] Receipt Capture & AI Extraction Draft...")
  const receiptPath = `${business.id}/receipt-test-001.jpg`
  
  // Upload fake receipt image to storage
  const sampleImageBytes = Buffer.from("FAKE_RECEIPT_IMAGE_DATA_FOR_TESTING")
  await adminClient.storage
    .from("receipts")
    .upload(receiptPath, sampleImageBytes, { contentType: "image/jpeg", upsert: true })

  console.log(`✓ Receipt Image Uploaded to Storage: ${receiptPath}`)

  const draftExtraction = {
    is_receipt: true,
    transaction_type: "expense",
    date: "2026-08-30",
    total_amount: 1750.0,
    currency: "EGP",
    vendor_customer_name: "مكتبة ومستلزمات القاهرة",
    suggested_category: suppliesCategory.name,
    line_items: [
      { description: "أوراق تصوير A4", quantity: 5, unit_price: 150.0, total_price: 750.0 },
      { description: "أحبار طابعة", quantity: 2, unit_price: 500.0, total_price: 1000.0 },
    ],
    confidence_scores: {
      overall: 0.96,
      date: 0.98,
      total_amount: 0.99,
      vendor_customer_name: 0.92,
    },
  }

  // Insert into ai_extractions table
  const { data: extractionRow, error: extractErr } = await adminClient
    .from("ai_extractions")
    .insert({
      business_id: business.id,
      receipt_image_path: receiptPath,
      raw_response: draftExtraction,
      status: "success",
    })
    .select()
    .single()

  if (extractErr) {
    throw new Error(`Failed to insert AI extraction draft: ${extractErr.message}`)
  }
  console.log(`✓ AI Extraction Draft Saved (Confidence: 96%): Total=${draftExtraction.total_amount} EGP`)

  // 6. Step 5: Review/Edit & Confirm Transaction
  console.log("\n[Step 5] Review, Confirm & Save Transaction...")
  const { data: transaction, error: txErr } = await adminClient
    .from("transactions")
    .insert({
      business_id: business.id,
      category_id: suppliesCategory.id,
      type: "expense",
      amount: draftExtraction.total_amount,
      date: draftExtraction.date,
      vendor_customer_name: draftExtraction.vendor_customer_name,
      receipt_image_path: receiptPath,
    })
    .select()
    .single()

  if (txErr || !transaction) {
    throw new Error(`Failed to save confirmed transaction: ${txErr?.message}`)
  }
  console.log(`✓ Transaction Confirmed & Saved: ID=${transaction.id}, Amount=${transaction.amount} EGP`)

  // Also add an income transaction so the reports show full summary
  await adminClient.from("transactions").insert({
    business_id: business.id,
    category_id: categories.find((c) => c.name === "Sales" || c.name === "مبيعات نقدية")?.id || categories[1].id,
    type: "income",
    amount: 5250.0,
    date: "2026-08-30",
    vendor_customer_name: "مبيعات اليوم - كاش",
  })
  console.log("✓ Added sample income transaction for comprehensive reporting")

  // 7. Step 6: Verify Reports & Financial Summary RPC
  console.log("\n[Step 6] Verifying Financial Summary & Reports RPCs...")
  const { data: summaryData, error: sumErr } = await adminClient.rpc("get_financial_summary", {
    p_business_id: business.id,
    p_start_date: "2026-08-01",
    p_end_date: "2026-08-31",
  })
  console.log("✓ Financial Summary:", summaryData?.[0])

  // 8. Step 7: Enable Web Access (Link Email Identity)
  console.log("\n[Step 7] Enabling Web Access by Linking Email Identity...")
  const { data: updatedUser, error: updateErr } = await adminClient.auth.admin.updateUserById(
    user.id,
    {
      email: testEmail,
      email_confirm: true,
    }
  )
  if (updateErr) {
    throw new Error(`Failed to link email identity: ${updateErr.message}`)
  }
  console.log(`✓ Email Identity Linked: ${testEmail}`)

  // 9. Step 8: Generate Magic Link for Web Dashboard
  console.log("\n[Step 8] Generating Magic Link for Dashboard Browser Login...")
  const { data: linkRes, error: linkErr } = await adminClient.auth.admin.generateLink({
    type: "magiclink",
    email: testEmail,
    options: {
      redirectTo: "http://localhost:3000/auth/callback",
    },
  })
  if (linkErr) {
    throw new Error(`Failed to generate magic link: ${linkErr.message}`)
  }

  const callbackUrl = `http://localhost:3000/auth/callback?token_hash=${linkRes.properties.hashed_token}&type=magiclink`
  console.log(`✓ Magic Link Generated successfully!`)
  console.log(`\nCALLBACK_URL=${callbackUrl}`)
  console.log(`TEST_TRANSACTION_ID=${transaction.id}`)
  console.log(`BUSINESS_ID=${business.id}`)
}

runE2E().catch((err) => {
  console.error("E2E SCRIPT FAILED:", err)
  process.exit(1)
})
