import Foundation

struct AISafetyResponse: Codable {
    let isSafe: Bool
    let message: String
}

struct AISafetyRequest: Codable {
    let goal: String
    let answers: [QuestionAnswerRequest]
    let correction: String?
}

enum AISafetyServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(
        statusCode: Int,
        message: String,
        retryable: Bool
    )
    case invalidDecision
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The AI safety service URL is invalid."
            
        case .invalidResponse:
            return "Wave couldn't communicate with its safety service. Please try again."
            
        case .serverError(_, let message, let retryable):
            if retryable {
                return "Wave couldn't verify this request's safety. Please try again shortly."
            }
            
            return message
            
        case .invalidDecision:
            return "Wave couldn't verify this request's safety. Please try again."
        }
    }
}

private struct AISafetyErrorPayload: Decodable {
    let error: String?
    let retryable: Bool?
}

final class AISafetyService {
    
    static let shared = AISafetyService()
    
    private init() {}
    
    private let functionURL =
    "https://lyxxusgyaqknqktljjbp.supabase.co/functions/v1/ai-safety"
    
    private let supabaseAnonKey =
    "sb_publishable__F3VyIpU8JdE8fGGd7y5nA_3hZ0bp35"
    
    func check(
        goal: String,
        answers: [QuestionAnswerRequest],
        correction: String?
    ) async throws -> AISafetyResponse {
        
        guard let url = URL(string: functionURL) else {
            throw AISafetyServiceError.invalidURL
        }
        
        let requestBody = AISafetyRequest(
            goal: goal,
            answers: answers,
            correction: correction
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 90
        
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
        
        request.setValue(
            supabaseAnonKey,
            forHTTPHeaderField: "apikey"
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(
            for: request
        )
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AISafetyServiceError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let payload = try? JSONDecoder().decode(
                AISafetyErrorPayload.self,
                from: data
            )
            
            let serverMessage = payload?.error?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            let message: String
            
            if let serverMessage, !serverMessage.isEmpty {
                message = serverMessage
            } else {
                message = "The safety service returned an error."
            }
            
            let retryableStatuses: Set<Int> = [
                408, 429, 500, 502, 503, 504
            ]
            
            throw AISafetyServiceError.serverError(
                statusCode: httpResponse.statusCode,
                message: message,
                retryable: payload?.retryable == true
                || retryableStatuses.contains(
                    httpResponse.statusCode
                )
            )
        }
        
        let safetyResponse: AISafetyResponse
        
        do {
            safetyResponse = try JSONDecoder().decode(
                AISafetyResponse.self,
                from: data
            )
        } catch {
            throw AISafetyServiceError.invalidDecision
        }
        
        guard !safetyResponse.message
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty else {
            throw AISafetyServiceError.invalidDecision
        }
        
        // Both outcomes are valid decisions:
        // isSafe == true  -> the request may continue.
        // isSafe == false -> the request must be blocked.
        // An error is neither outcome and must not be treated as approval.
        return safetyResponse
    }
}
