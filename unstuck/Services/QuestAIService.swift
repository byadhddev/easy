import Foundation

// MARK: - Quest AI Service
// Calls the Unstuck backend (Cloudflare Worker) which proxies to Gemini.
// NO API keys are stored on the client. Only APP_SECRET is used — a low-sensitivity
// shared secret that prevents public abuse of the endpoint.
//
// Set in Secrets.xcconfig (never committed):
//   BACKEND_URL = https://unstuck-backend.<your-subdomain>.workers.dev
//   APP_SECRET  = <your shared secret>

struct QuestAIService {

    // Read from Info.plist, populated via Secrets.xcconfig
    private var backendURL: String {
        Bundle.main.object(forInfoDictionaryKey: "BACKEND_URL") as? String ?? ""
    }

    private var appSecret: String {
        Bundle.main.object(forInfoDictionaryKey: "APP_SECRET") as? String ?? ""
    }

    // MARK: - Generate Quest

    func generateQuest(userInput: String, energy: EnergyLevel) async throws -> QuestResponse {
        guard !backendURL.isEmpty, let url = URL(string: "\(backendURL)/api/quest") else {
            throw QuestError.notConfigured
        }

        let body: [String: String] = [
            "userInput":    userInput,
            "energyLevel":  energy.rawValue,
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json",  forHTTPHeaderField: "Content-Type")
        request.setValue(appSecret,           forHTTPHeaderField: "X-App-Secret")
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
        case .notConfigured: return "Backend URL not configured. Check Secrets.xcconfig."
        case .networkError:  return AppCopy.Shared.errorGeneric
        case .unauthorized:  return "App secret mismatch. Check Secrets.xcconfig."
        case .apiError:      return AppCopy.Shared.errorGeneric
        }
    }
}


