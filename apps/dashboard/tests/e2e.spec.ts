import { test, expect } from '@playwright/test';
import { createClient } from '@supabase/supabase-js';
import WebSocket from 'ws';

const SUPABASE_URL = "http://127.0.0.1:54321";
const SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU";

const adminClient = createClient(SUPABASE_URL, SERVICE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
  realtime: { transport: WebSocket as any }
});

test.describe('Dashboard E2E', () => {
  let businessId: string;
  let testUser: any;
  const testPhone = "+201099887766";
  const testEmail = "elamal.owner@hesably.com";

  test.beforeAll(async () => {
    // 1. Clean up any previous test user with this phone or email
    const { data: userList } = await adminClient.auth.admin.listUsers();
    const existingUser = userList?.users?.find(
      (u) => u.phone === testPhone || u.email === testEmail
    );
    if (existingUser) {
      await adminClient.auth.admin.deleteUser(existingUser.id);
    }

    // 2. Step 1: New User via Phone Auth
    const { data: createdUserData, error: createErr } = await adminClient.auth.admin.createUser({
      phone: testPhone,
      phone_confirm: true,
      email: testEmail,
      email_confirm: true,
      user_metadata: { name: "أحمد عبد الله" },
    });
    if (createErr || !createdUserData.user) throw createErr;
    testUser = createdUserData.user;

    // 3. Step 2: Business Onboarding
    const { data: business, error: bizErr } = await adminClient
      .from("businesses")
      .insert({
        owner_id: testUser.id,
        name: "سوبرماركت الأمل",
        type: "retail",
        currency: "EGP",
      })
      .select()
      .single();
    if (bizErr || !business) throw bizErr;
    businessId = business.id;

  });

  test('Dashboard loads via Magic Link and displays business data', async ({ page }) => {
    // Generate Magic Link
    const { data: linkRes, error: linkErr } = await adminClient.auth.admin.generateLink({
      type: "magiclink",
      email: testEmail,
      options: {
        redirectTo: "http://localhost:3000/auth/callback",
      },
    });
    if (linkErr || !linkRes?.properties) throw linkErr ?? new Error("Failed to generate magic link");
    expect(linkErr).toBeNull();
    
    const callbackUrl = `http://localhost:3000/auth/callback?token_hash=${linkRes.properties.hashed_token}&type=magiclink`;
    
    // Navigate to callback URL

    await page.goto(callbackUrl);

    // Assert successful redirect to dashboard
    await expect(page).toHaveURL("http://localhost:3000/");

    // Wait for the business name to be visible (testing RTL/Arabic support & data loading)
    await expect(page.locator('text=سوبرماركت الأمل').first()).toBeVisible({ timeout: 10000 });
  });

  test('Unlinked account is blocked with clear message', async ({ page }) => {
    const unlinkedEmail = "unlinked.user@hesably.com";

    // Clean up if exists
    const { data: userList } = await adminClient.auth.admin.listUsers();
    const existing = userList?.users?.find((u) => u.email === unlinkedEmail);
    if (existing) {
      await adminClient.auth.admin.deleteUser(existing.id);
    }

    // Create user without business
    const { data: unlinkedUserData } = await adminClient.auth.admin.createUser({
      email: unlinkedEmail,
      email_confirm: true,
    });

    const { data: linkRes, error: linkErr } = await adminClient.auth.admin.generateLink({
      type: "magiclink",
      email: unlinkedEmail,
      options: {
        redirectTo: "http://localhost:3000/auth/callback",
      },
    });
    if (linkErr || !linkRes?.properties) throw linkErr ?? new Error("Failed to generate magic link");

    const callbackUrl = `http://localhost:3000/auth/callback?token_hash=${linkRes.properties.hashed_token}&type=magiclink`;
    await page.goto(callbackUrl);

    // Verify unlinked block message appears
    await expect(page.locator('text=الحساب غير مرتبط بنشاط تجاري').first()).toBeVisible({ timeout: 10000 });

    // Cleanup
    if (unlinkedUserData?.user) {
      await adminClient.auth.admin.deleteUser(unlinkedUserData.user.id);
    }
  });
});
