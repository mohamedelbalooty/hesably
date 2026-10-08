import { createClient } from "@supabase/supabase-js"

const SUPABASE_URL = "http://127.0.0.1:54321"
const SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"

const supabase = createClient(SUPABASE_URL, SERVICE_KEY)

async function check() {
  const { data: businesses } = await supabase.from("businesses").select("*")
  console.log("Businesses:", businesses)

  const { data: transactions } = await supabase.from("transactions").select("*")
  console.log("Transactions count:", transactions?.length)
  console.log("Transactions:", transactions)
}

check()
