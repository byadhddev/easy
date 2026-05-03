import Foundation

// MARK: - Quest AI Service
// Talks to Google Gemini 2.0 Flash. Local API key via Info.plist (key: GEMINI_API_KEY).
// No data is stored server-side. Prompts are ephemeral.

struct QuestAIService {

    private let model = "gemini-flash-lite-latest"
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"

    // Fetch API key from Info.plist (key: GEMINI_API_KEY)
    private var apiKey: String {
        ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? ""
    }

    private var apiURL: URL {
        URL(string: "\(baseURL)/\(model):generateContent?key=\(apiKey)")!
    }

    // MARK: - Generate Quest

    func generateQuest(userInput: String, energy: EnergyLevel) async throws -> QuestResponse {
        let body: [String: Any] = [
            "system_instruction": [
                "parts": [["text": systemPrompt(energy: energy)]]
            ],
            "contents": [
                ["role": "user", "parts": [["text": userInput]]]
            ],
            "generationConfig": [
                "responseMimeType": "application/json",
                "temperature": 0.75,
                "maxOutputTokens": 300,
            ]
        ]

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw QuestError.apiError
        }

        let geminiResponse = try JSONDecoder().decode(GeminiCompletion.self, from: data)
        guard let text = geminiResponse.candidates.first?.content.parts.first?.text,
              let jsonData = text.data(using: .utf8) else {
            throw QuestError.parseError
        }

        return try JSONDecoder().decode(QuestResponse.self, from: jsonData)
    }

    // MARK: - System Prompt

    private func systemPrompt(energy: EnergyLevel) -> String {
        let energyContext: String
        switch energy {
        case .low:    energyContext = "The person is running on fumes — exhausted and overwhelmed. Keep the action extremely small."
        case .medium: energyContext = "The person has some capacity but is still carrying weight. The action should be minimal but not trivial."
        case .okay:   energyContext = "The person has enough energy. The action can be slightly more involved but still a single step."
        }

        return """
        You are a calm, non-judgmental companion helping someone who is anxious, overwhelmed, or stuck.
        
        Context: \(energyContext)
        
        Your response must be a JSON object with exactly these three keys:
        - "comfort": A 2-3 sentence empathy paragraph. Acknowledge what they're feeling — be specific to what they said, not generic. Never use toxic positivity. Never say "amazing" or "great job." Tone: a wise, calm friend.
        - "step": ONE minimal action — the smallest possible step that moves them forward. Max 2 sentences. Be concrete and specific. Start with a verb.
        - "stepTitle": A short 4-6 word title summarizing the quest (for display in a card). Lowercase.
        
        Rules:
        - Never diagnose or give clinical advice.
        - Never suggest multiple steps.
        - If the situation sounds like a crisis, gently note that professional support exists — without alarm.
        - Total response under 150 words.
        """
    }
}

// MARK: - Response Models

struct QuestResponse: Equatable, Decodable {
    let comfort: String
    let step: String
    let stepTitle: String
}

// Gemini API response shape
private struct GeminiCompletion: Decodable {
    let candidates: [Candidate]
    struct Candidate: Decodable {
        let content: Content
        struct Content: Decodable {
            let parts: [Part]
            struct Part: Decodable {
                let text: String
            }
        }
    }
}

enum QuestError: LocalizedError {
    case apiError
    case parseError
    case noAPIKey

    var errorDescription: String? {
        switch self {
        case .apiError:   return AppCopy.Shared.errorGeneric
        case .parseError: return AppCopy.Shared.errorGeneric
        case .noAPIKey:   return "API key not configured."
        }
    }
}

