import { createClient } from "@supabase/supabase-js"

const SUPABASE_URL = "http://127.0.0.1:54321"
const SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"

const supabase = createClient(SUPABASE_URL, SERVICE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
})

async function run() {
  console.log("Seeding demo user...")

  // 1. Create or find demo user
  const email = "demo@hesably.com"
  const { data: users, error: listErr } = await supabase.auth.admin.listUsers()
  let user = users?.users?.find((u) => u.email === email)

  if (!user) {
    const { data: newUser, error: createErr } = await supabase.auth.admin.createUser({
      email,
      email_confirm: true,
      user_metadata: { name: "محمد البلوطي" },
    })
    if (createErr) {
      console.error("Failed to create user:", createErr)
      return
    }
    user = newUser.user
    console.log("Created user:", user.id)
  } else {
    console.log("Found existing user:", user.id)
  }

  // 2. Create business
  const { data: existingBiz } = await supabase
    .from("businesses")
    .select("*")
    .eq("owner_id", user.id)
    .maybeSingle()

  let businessId = existingBiz?.id
  if (!existingBiz) {
    const { data: newBiz, error: bizErr } = await supabase
      .from("businesses")
      .insert({
        owner_id: user.id,
        name: "مؤسسة النور للتجارة",
        type: "تجارة تجزئة",
        currency: "EGP",
      })
      .select()
      .single()

    if (bizErr) {
      console.error("Failed to create business:", bizErr)
      return
    }
    businessId = newBiz.id
    console.log("Created business:", businessId)
  } else {
    console.log("Found existing business:", businessId)
  }

  // 3. Ensure Categories
  const { data: categories } = await supabase
    .from("categories")
    .select("*")
    .eq("business_id", businessId)

  let catMap = {}
  if (!categories || categories.length === 0) {
    const defaultNames = ["مشتريات وبضاعة", "إيجار ومرافق", "رواتب", "مبيعات نقدية", "خدمات واستشارات"]
    const inserts = defaultNames.map((name) => ({
      business_id: businessId,
      name,
      is_default: true,
      is_hidden: false,
    }))
    const { data: insertedCats } = await supabase
      .from("categories")
      .insert(inserts)
      .select()

    insertedCats?.forEach((c) => {
      catMap[c.name] = c.id
    })
    console.log("Created categories:", Object.keys(catMap))
  } else {
    categories.forEach((c) => {
      catMap[c.name] = c.id
    })
    console.log("Existing categories:", Object.keys(catMap))
  }

  // 4. Create sample transactions for current month
  const { data: existingTx } = await supabase
    .from("transactions")
    .select("id")
    .eq("business_id", businessId)

  if (!existingTx || existingTx.length === 0) {
    const today = new Date().toISOString().split("T")[0]
    const sampleTx = [
      {
        business_id: businessId,
        category_id: Object.values(catMap)[0],
        type: "expense",
        amount: 3500.0,
        date: today,
        vendor_customer_name: "شركة الأهرام للتوريدات",
      },
      {
        business_id: businessId,
        category_id: Object.values(catMap)[1] || Object.values(catMap)[0],
        type: "expense",
        amount: 1200.0,
        date: today,
        vendor_customer_name: "شركة الكهرباء",
      },
      {
        business_id: businessId,
        category_id: Object.values(catMap)[3] || Object.values(catMap)[0],
        type: "income",
        amount: 8500.0,
        date: today,
        vendor_customer_name: "مبيعات الفرع الرئيسي",
      },
      {
        business_id: businessId,
        category_id: Object.values(catMap)[3] || Object.values(catMap)[0],
        type: "income",
        amount: 4200.0,
        date: today,
        vendor_customer_name: "عميل نقدي",
      },
    ]

    const { error: txErr } = await supabase.from("transactions").insert(sampleTx)
    if (txErr) {
      console.error("Failed to insert transactions:", txErr)
    } else {
      console.log("Successfully seeded transactions!")
    }
  }

  // 5. Generate magic link for demo user to authenticate directly in browser tests
  const { data: linkData, error: linkErr } = await supabase.auth.admin.generateLink({
    type: "magiclink",
    email,
    options: {
      redirectTo: "http://localhost:3000/auth/callback",
    },
  })

  if (linkErr) {
    console.error("Link error:", linkErr)
  } else {
    console.log("\nDEMO_MAGIC_LINK:", linkData.properties.action_link)
    console.log("PROPERTIES:", linkData.properties)
    const callbackUrl = `http://localhost:3000/auth/callback?token_hash=${linkData.properties.hashed_token}&type=magiclink`
    console.log("DIRECT_CALLBACK_URL:", callbackUrl)
  }
}

run()
