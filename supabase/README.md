# Supabase

Server-side code for Hardly Working. The iOS client lives in `../HardlyWorking/`.

## Edge Functions

### `delete_account`

Performs a full account deletion for the calling user — including the
`auth.users` row, which the iOS client cannot delete directly because
`auth.admin.deleteUser` requires the `SUPABASE_SERVICE_ROLE_KEY`.

The iOS client invokes it from `SupabaseManager.deleteAccount()` via
`client.functions.invoke("delete_account")`. The user's JWT is sent in the
`Authorization` header automatically; the function reads it to identify the
caller, then uses an admin client to wipe app data and the auth identity.

#### Deploy

```sh
# One-time
brew install supabase/tap/supabase
supabase login
supabase link --project-ref <your-project-ref>

# Deploy or redeploy
supabase functions deploy delete_account
```

The function relies on `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and
`SUPABASE_SERVICE_ROLE_KEY`, all auto-provided by the Functions runtime.
