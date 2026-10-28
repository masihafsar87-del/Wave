import Foundation

enum AIPlannerError: LocalizedError {
    case invalidResponse
    case serverError(statusCode: Int, message: String)
    case invalidData(response: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Wave couldn't read the AI understanding service's response. Please try again."
            
        case .serverError(_, let message):
            return message
            
        case .invalidData:
            return "The AI returned an understanding Wave couldn't read. Please try again."
        }
    }
}

private struct AIPlannerErrorPayload: Decodable {
    let error: String?
    let retryable: Bool?
}

final class AIPlannerService {
    
    static let shared = AIPlannerService()
    
    private init() {}
    
    private let functionURL =
    "https://lyxxusgyaqknqktljjbp.supabase.co/functions/v1/ai-planner"
    
    private let supabaseAnonKey =
    "sb_publishable__F3VyIpU8JdE8fGGd7y5nA_3hZ0bp35"
    
    func generateUnderstanding(
        from requestBody: AIPlannerRequest
    ) async throws -> AIPlannerResponse {
        
        guard let url = URL(string: functionURL) else {
            throw AIPlannerError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
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
            throw AIPlannerError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = Self.errorMessage(
                from: data,
                statusCode: httpResponse.statusCode
            )
            
            throw AIPlannerError.serverError(
                statusCode: httpResponse.statusCode,
                message: message
            )
        }
        
        do {
            return try JSONDecoder().decode(
                AIPlannerResponse.self,
                from: data
            )
        } catch {
            let rawResponse = String(
                data: data,
                encoding: .utf8
            ) ?? "No response body"
            
            throw AIPlannerError.invalidData(
                response: rawResponse
            )
        }
    }
    
    private static func errorMessage(
        from data: Data,
        statusCode: Int
    ) -> String {
        
        let payload = try? JSONDecoder().decode(
            AIPlannerErrorPayload.self,
            from: data
        )
        
        let retryableStatuses: Set<Int> = [
            408, 429, 500, 502, 503, 504
        ]
        
        if payload?.retryable == true
            || retryableStatuses.contains(statusCode) {
            return "The AI service is temporarily busy or unavailable. Please try again shortly."
        }
        
        if let message = payload?.error?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !message.isEmpty {
            return message
        }
        
        return "The AI understanding service returned an error (HTTP \(statusCode))."
    }
}
