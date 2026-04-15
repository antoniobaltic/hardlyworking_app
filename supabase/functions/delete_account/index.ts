// Supabase Edge Function: delete_account
//
// Performs full account deletion for the authenticated caller. This is the
// only path that can remove the row from `auth.users` — the supabase-js anon
// client cannot, since `auth.admin.deleteUser` requires the service role key.
//
// Flow:
//   1. Verify caller identity by reading the Authorization JWT.
//   2. Use a service-role admin client to delete the user's app data:
//      group_members, daily_stats, friend_groups (owned), profiles.
//   3. Call `auth.admin.deleteUser(userId)` to wipe the auth identity.
//
// Returns 200 on success, 401 if the caller can't be authenticated, 500 on
// admin failure. App-data deletes are best-effort — failures don't abort the
// auth deletion (the next sign-up under the same Apple ID will create a fresh
// profiles row anyway).
//
// Deploy:
//   supabase functions deploy delete_account
//
// Required env vars (auto-provided by Supabase Functions runtime):
//   SUPABASE_URL
//   SUPABASE_ANON_KEY
//   SUPABASE_SERVICE_ROLE_KEY

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req: Request) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return jsonResponse({ error: "Missing authorization header" }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    return jsonResponse({ error: "Server misconfigured" }, 500);
  }

  // Verify caller identity using the user-scoped client.
  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  const userId = userData.user.id;

  // Admin client (service role) for full cleanup.
  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  // App-data cleanup. Order matters to avoid FK constraint violations when
  // ON DELETE CASCADE isn't configured on the relationships.
  //
  //   1. Clear memberships IN groups this user owns (other users joined)
  //   2. Clear this user's own memberships in groups they joined
  //   3. Clear daily_stats
  //   4. Delete groups this user owns (now safe — no members, no FK blocks)
  //   5. Delete the user's profile row
  //   6. Finally, delete the auth.users row
  const { data: ownedGroups } = await adminClient
    .from("friend_groups")
    .select("id")
    .eq("created_by", userId);
  const ownedGroupIds = (ownedGroups ?? []).map((g: { id: string }) => g.id);
  if (ownedGroupIds.length > 0) {
    await adminClient
      .from("group_members")
      .delete()
      .in("group_id", ownedGroupIds);
  }
  await adminClient.from("group_members").delete().eq("user_id", userId);
  await adminClient.from("daily_stats").delete().eq("user_id", userId);
  await adminClient.from("friend_groups").delete().eq("created_by", userId);
  await adminClient.from("profiles").delete().eq("id", userId);

  // Final and required step: remove the auth.users row.
  const { error: deleteError } = await adminClient.auth.admin.deleteUser(userId);
  if (deleteError) {
    return jsonResponse(
      { error: `Auth deletion failed: ${deleteError.message}` },
      500,
    );
  }

  return jsonResponse({ success: true }, 200);
});

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
