---
name: supabase
description: Supabase patterns for Nuxt/Nitro projects — client setup, Row Level Security, SSR auth, migrations, storage. Use for any task touching Supabase, RLS policies, supabase-js, auth sessions, database schema, or storage buckets.
---

# Supabase Patterns

## Client Setup

- **Client-side**: anon key via `@nuxtjs/supabase` module or a Nuxt plugin; RLS is the security boundary.
- **Server-side (Nitro)**: service-role client in `server/utils/supabase.ts`, singleton, `persistSession: false`. Service-role key NEVER reaches the browser bundle — keep it out of `runtimeConfig.public`.

```
SUPABASE_URL=...
SUPABASE_ANON_KEY=...            # public, RLS-protected
SUPABASE_SERVICE_ROLE_KEY=...    # server-only, bypasses RLS
```

## RLS — Non-negotiable Rules

1. `ALTER TABLE x ENABLE ROW LEVEL SECURITY;` on **every** table, including ones "only the server touches".
2. SELECT/DELETE policies use `USING`; INSERT uses `WITH CHECK`; UPDATE uses **both**.
3. Scope by membership, not by trust:

```sql
CREATE POLICY "members_read" ON items FOR SELECT
  USING (tenant_id IN (SELECT tenant_id FROM tenant_members WHERE user_id = auth.uid()));

CREATE POLICY "members_insert" ON items FOR INSERT
  WITH CHECK (
    tenant_id IN (SELECT tenant_id FROM tenant_members WHERE user_id = auth.uid())
    AND created_by = auth.uid()
  );
```

4. Test policies with the anon key, not the service key — service role bypasses RLS and hides mistakes.
5. Wrap membership subqueries in a `SECURITY DEFINER` function if they recurse into the same table.

## Auth

- **Server-side verification**: never trust `getSession()` on the server (reads unverified cookie/JWT). Use `supabase.auth.getUser(token)` or `getClaims()` — these verify.
- Identity comes from the verified token, never from a client-sent user ID.
- Client composable wraps `signInWithPassword` / `signOut` / `onAuthStateChange`; redirect logic in route middleware, not components.

## Queries

- Explicit column selects, never `select('*')` in production paths
- Relations via nested select: `select('id, title, author:users(id, full_name)')`
- Always scope writes: `.eq('tenant_id', tenantId)` on update/delete even when RLS also enforces it (defense in depth)
- Handle `error` on every call — throw `createError` server-side; return null + store notification client-side
- Generate types: `supabase gen types typescript --project-id <id> > shared/types/supabase.ts`; use `Database['public']['Tables']['x']['Row' | 'Insert' | 'Update']`

## Migrations

- All schema changes as SQL files via `supabase migration new <name>` — never dashboard-only changes
- Migrations are append-only; fix mistakes with a new migration
- Every new table migration includes its RLS enable + policies in the same file
- `supabase db reset` locally to verify the full chain replays

## Storage

- One bucket per content type; private by default, public only for truly public assets
- Storage policies mirror table RLS (path prefix = user/tenant ID: `avatars/{user_id}/...`)
- Signed URLs for private content, short expiry
- Validate MIME type and size server-side before upload

## Checklist

- [ ] RLS enabled + policies on every table touched
- [ ] Service key server-only
- [ ] Server auth via `getUser`/`getClaims`, not `getSession`
- [ ] Errors handled on every Supabase call
- [ ] Schema change = migration file including policies
