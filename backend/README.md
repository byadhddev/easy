# Unstuck — Backend

Cloudflare Worker that proxies quest generation requests from the iOS app to Gemini Flash Lite.  
The Gemini API key **never touches the client**.

---

## Architecture

```
iOS App
  │  POST /api/quest
  │  Headers: X-App-Secret, Content-Type: application/json
  │  Body: { userInput, energyLevel }
  ▼
Cloudflare Worker  (this repo — backend/)
  │  env.GEMINI_API_KEY  (secret, set via wrangler)
  │  env.APP_SECRET      (secret, set via wrangler)
  ▼
Gemini Flash Lite API
  ▼
{ comfort, step, stepTitle }  →  iOS App
```

---

## Local Development

```bash
cd backend
npm install
npx wrangler dev
```

The worker runs at `http://localhost:8787`.  
Set local secrets in `.dev.vars` (never committed):

```ini
GEMINI_API_KEY=AIza...
APP_SECRET=your-local-secret
```

Test it:
```bash
curl -X POST http://localhost:8787/api/quest \
  -H "Content-Type: application/json" \
  -H "X-App-Secret: your-local-secret" \
  -d '{"userInput":"I keep avoiding calling the doctor","energyLevel":"medium"}'
```

---

## Deploy to Cloudflare

### 1. Login
```bash
npx wrangler login
```

### 2. Set secrets (one-time)
```bash
npx wrangler secret put GEMINI_API_KEY
# paste your Google AI Studio key

npx wrangler secret put APP_SECRET
# paste a random secret string (use: openssl rand -hex 32)
```

### 3. Deploy
```bash
npm run deploy
```

Your worker URL will be:  
`https://unstuck-backend.<your-subdomain>.workers.dev`

---

## iOS Setup (after deploy)

Copy `Secrets.xcconfig.template` → `Secrets.xcconfig` and fill in:

```ini
BACKEND_URL = https://unstuck-backend.<your-subdomain>.workers.dev
APP_SECRET  = <same value you set in wrangler>
```

Both keys must be referenced in `Info.plist`:
```xml
<key>BACKEND_URL</key>
<string>$(BACKEND_URL)</string>
<key>APP_SECRET</key>
<string>$(APP_SECRET)</string>
```

---

## Endpoint

### `POST /api/quest`

**Headers**
| Header | Value |
|--------|-------|
| `Content-Type` | `application/json` |
| `X-App-Secret` | Your shared secret |

**Request body**
```json
{
  "userInput": "I keep putting off calling the dentist",
  "energyLevel": "low" | "medium" | "okay"
}
```

**Response (200)**
```json
{
  "comfort": "You've been carrying this for a while...",
  "step": "Send a text to the clinic: 'I need to reschedule — please reply today.'",
  "stepTitle": "one message to the clinic"
}
```

**Error responses**
| Status | Meaning |
|--------|---------|
| 400 | Missing or invalid body |
| 401 | Wrong or missing `X-App-Secret` |
| 502 | Gemini upstream error |
