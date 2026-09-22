---
name: vercel
description: Deploying and operating Nuxt applications on Vercel — zero-config deploys, environment variables, ISR/caching via route rules, Fluid Compute, preview vs production. Use for any deployment, env var, caching, or Vercel configuration task.
---

# Vercel for Nuxt

## Deploy

- Nuxt deploys zero-config: Vercel detects the framework, Nitro uses the `vercel` preset automatically. No `vercel.json` needed for the basic case.
- `vercel` → preview deployment; `vercel --prod` → production. Every git push to a linked repo gets a preview URL.
- Promote a verified preview instead of rebuilding: `vercel promote <deployment-url>`.
- Rollback: `vercel rollback` to the previous production deployment.

## Environment Variables

- Manage via `vercel env` (or dashboard); three scopes: development, preview, production.
- `vercel env pull .env.local` syncs local dev with the platform — never hand-maintain a second copy.
- Server secrets (e.g. `SUPABASE_SERVICE_ROLE_KEY`) go in plain env vars read by `runtimeConfig`; public values in `NUXT_PUBLIC_*` → `runtimeConfig.public`.
- Nuxt convention: `NUXT_` prefix overrides `runtimeConfig` keys at runtime (`NUXT_API_SECRET` → `runtimeConfig.apiSecret`).

## Rendering & Caching (route rules)

ISR works on Nuxt on Vercel via Nitro route rules:

```ts
// nuxt.config.ts
routeRules: {
  '/':          { prerender: true },          // static at build
  '/blog/**':   { isr: 3600 },                // ISR, revalidate hourly
  '/dashboard/**': { ssr: false },            // client-only SPA section
  '/api/**':    { cors: true },
}
```

- `isr: true` = cache until next deploy; `isr: <seconds>` = time-based revalidation.
- Static assets get immutable caching automatically.
- Don't cache personalized/authenticated responses — no `isr` on routes reading session state.

## Functions (Fluid Compute)

- Server routes run as Vercel Functions with Fluid Compute: full Node.js, instance reuse across requests, minimal cold starts. Module-level singletons (DB clients) are safe and encouraged.
- Default timeout 300s — long work still belongs in background/queue patterns, not request handlers.
- Cron: `vercel.json` (or `vercel.ts`) `crons` hitting a Nitro route, e.g. `{ "path": "/api/cron/cleanup", "schedule": "0 3 * * *" }` — protect the route by checking a secret header.

## Preview Workflow

- Every PR → preview URL with production-like environment; test there before promoting.
- Preview env vars can point at a staging Supabase project to keep production data out of previews.
- Protect previews (Vercel Authentication) when the app handles real data.

## Checklist

- [ ] Env vars set per scope, `.env.local` pulled not hand-written
- [ ] No service keys in `NUXT_PUBLIC_*` / `runtimeConfig.public`
- [ ] Route rules define caching intent explicitly for content routes
- [ ] No ISR on authenticated routes
- [ ] Verified on preview URL before `--prod` or promote
