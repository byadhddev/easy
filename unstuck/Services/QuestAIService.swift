import Foundation

// MARK: - Quest AI Service
// Calls the Unstuck backend (Cloudflare Worker) which proxies to Gemini.
// NO API keys are stored on the client.
//
// Secrets live in Secrets.swift (gitignored — copy from Secrets.swift.template).
// Never reads from Info.plist or xcconfig — just a plain Swift enum.

struct QuestAIService {

    // MARK: - Generate Quest

    func generateQuest(userInput: String, energy: EnergyLevel) async throws -> QuestResponse {
        guard let url = URL(string: "\(AppSecrets.backendURL)/api/quest") else {
            throw QuestError.notConfigured
        }

        let body: [String: String] = [
            "userInput":    userInput,
            "energyLevel":  energy.rawValue,
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json",  forHTTPHeaderField: "Content-Type")
        request.setValue(AppSecrets.appSecret, forHTTPHeaderField: "X-App-Secret")
        request.httpBody = try JSONEncoder().encode(body)
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw QuestError.networkError
        }

        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(QuestResponse.self, from: data)
        case 401:
            throw QuestError.unauthorized
        default:
            throw QuestError.apiError
        }
    }
}

// MARK: - Response Models

struct QuestResponse: Equatable, Decodable {
    let comfort: String
    let step: String
    let stepTitle: String
}

// MARK: - Errors

enum QuestError: LocalizedError {
    case notConfigured
    case networkError
    case unauthorized
    case apiError

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Backend not configured. Add Secrets.swift to the project."
        case .networkError:  return AppCopy.Shared.errorGeneric
        case .unauthorized:  return "App secret mismatch. Check Secrets.swift."
        case .apiError:      return AppCopy.Shared.errorGeneric
        }
    }
}



