# Secrets & Security Guide

## Architecture (v2 — Backend Proxy)

The Gemini API key is **never stored on the iOS device**. All AI calls route through the Cloudflare Worker backend.

```
iOS App  ──►  Cloudflare Worker  ──►  Gemini Flash Lite
              (holds GEMINI_API_KEY)
              (validates APP_SECRET)
```

The iOS app only holds `APP_SECRET` — a shared secret that prevents public abuse of the endpoint. If it leaks, rotate it without touching the Gemini key.

---

## Local iOS Setup

```sh
cp Secrets.xcconfig.template Secrets.xcconfig
# fill in BACKEND_URL and APP_SECRET
```

`Secrets.xcconfig` is gitignored (`*.xcconfig`). Reference both keys in `Info.plist`:
```xml
<key>BACKEND_URL</key><string>$(BACKEND_URL)</string>
<key>APP_SECRET</key><string>$(APP_SECRET)</string>
```

---

## Backend Secrets (Cloudflare)

```sh
cd backend
npx wrangler secret put GEMINI_API_KEY   # your Google AI Studio key
npx wrangler secret put APP_SECRET       # openssl rand -hex 32
```

See `backend/README.md` for full deploy instructions.

---

## CI / Xcode Cloud

Inject only `BACKEND_URL` and `APP_SECRET` as build-time vars.  
`GEMINI_API_KEY` never leaves Cloudflare.

---

## Further hardening (future)

- Add **Apple App Attest** to verify requests come from your real iOS app
- **Rate-limit by IP** in the Cloudflare Worker
- Add **user auth (JWT)** for per-user tracking
- Run **`gitleaks`** in CI to catch accidental secret commits
