import { Hono } from 'hono'
import { cors } from 'hono/cors'

// MARK: - Environment bindings
// GEMINI_API_KEY is the only secret — set via `wrangler secret put GEMINI_API_KEY`
// RATE_LIMIT_KV is an optional KV namespace for IP-based rate limiting.
// No client secret needed — the backend IS the trust boundary.
type Bindings = {
  GEMINI_API_KEY: string
  RATE_LIMIT_KV?: KVNamespace   // optional: bind in wrangler.toml to enable rate limiting
}

// MARK: - Request / Response types

interface QuestRequest {
  userInput: string
  energyLevel: 'low' | 'medium' | 'okay'
}

interface QuestResponse {
  comfort: string
  step: string
  stepTitle: string
}

// MARK: - App

const app = new Hono<{ Bindings: Bindings }>()

app.use('*', cors({
  origin: '*', // Tighten with App Attest in v2
  allowMethods: ['POST', 'OPTIONS'],
  allowHeaders: ['Content-Type'],
}))

// Health check
app.get('/', (c) => c.json({ status: 'ok', service: 'unstuck-backend' }))

// MARK: - Quest generation endpoint
app.post('/api/quest', async (c) => {
  // IP-based rate limiting (requires RATE_LIMIT_KV namespace to be bound)
  if (c.env.RATE_LIMIT_KV) {
    const ip = c.req.header('CF-Connecting-IP') ?? 'unknown'
    const key = `rl:${ip}:${Math.floor(Date.now() / 60_000)}` // per-minute bucket
    const count = parseInt(await c.env.RATE_LIMIT_KV.get(key) ?? '0', 10)
    if (count >= 10) {
      return c.json({ error: 'Too many requests. Please wait a moment.' }, 429)
    }
    c.executionCtx.waitUntil(
      c.env.RATE_LIMIT_KV.put(key, String(count + 1), { expirationTtl: 120 })
    )
  }

  // Parse and validate body
  let body: QuestRequest
  try {
    body = await c.req.json<QuestRequest>()
  } catch {
    return c.json({ error: 'Invalid request body' }, 400)
  }

  const { userInput, energyLevel } = body
  if (!userInput?.trim()) {
    return c.json({ error: 'userInput is required' }, 400)
  }

  // Call Gemini
  try {
    const quest = await generateQuest(userInput.trim(), energyLevel ?? 'medium', c.env.GEMINI_API_KEY)
    return c.json(quest)
  } catch (err) {
    console.error('Gemini error:', err)
    return c.json({ error: 'Something went quiet. Try again in a moment.' }, 502)
  }
})

// MARK: - Gemini call

async function generateQuest(
  userInput: string,
  energyLevel: QuestRequest['energyLevel'],
  apiKey: string
): Promise<QuestResponse> {
  const model = 'gemini-flash-lite-latest'
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`

  const energyContext: Record<QuestRequest['energyLevel'], string> = {
    low:    'The person is running on fumes — exhausted and overwhelmed. Keep the action extremely small.',
    medium: 'The person has some capacity but is still carrying weight. The action should be minimal but not trivial.',
    okay:   'The person has enough energy. The action can be slightly more involved but still a single step.',
  }

  const systemPrompt = `You are a calm, non-judgmental companion helping someone who is anxious, overwhelmed, or stuck.

Context: ${energyContext[energyLevel]}

Your response must be a JSON object with exactly these three keys:
- "comfort": A 2-3 sentence empathy paragraph. Acknowledge what they're feeling — be specific to what they said, not generic. Never use toxic positivity. Never say "amazing" or "great job." Tone: a wise, calm friend.
- "step": ONE minimal action — the smallest possible step that moves them forward. Max 2 sentences. Be concrete and specific. Start with a verb.
- "stepTitle": A short 4-6 word title summarizing the quest (for display in a card). Lowercase.

Rules:
- Never diagnose or give clinical advice.
- Never suggest multiple steps.
- If the situation sounds like a crisis, gently note that professional support exists — without alarm.
- Total response under 150 words.`

  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      system_instruction: { parts: [{ text: systemPrompt }] },
      contents: [{ role: 'user', parts: [{ text: userInput }] }],
      generationConfig: {
        responseMimeType: 'application/json',
        temperature: 0.75,
        maxOutputTokens: 300,
      },
    }),
  })

  if (!res.ok) {
    throw new Error(`Gemini returned ${res.status}: ${await res.text()}`)
  }

  const data = await res.json() as {
    candidates: Array<{
      content: { parts: Array<{ text: string }> }
    }>
  }

  const text = data.candidates?.[0]?.content?.parts?.[0]?.text
  if (!text) throw new Error('Empty response from Gemini')

  const parsed = JSON.parse(text) as QuestResponse
  if (!parsed.comfort || !parsed.step || !parsed.stepTitle) {
    throw new Error('Incomplete response from Gemini')
  }

  return parsed
}

export default app
