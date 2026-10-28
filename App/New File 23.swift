import Foundation

struct AIInterviewResponse: Codable {
    let question: String
    let finished: Bool
}

enum AIInterviewerServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int, message: String)
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The AI interviewer URL is invalid."
            
        case .invalidResponse:
            return "Wave couldn't read the AI interviewer's response. Please try again."
            
        case .serverError(_, let message):
            return message
            
        case .invalidData:
            return "The AI interviewer returned a response Wave couldn't read. Please try again."
        }
    }
}

private struct AIInterviewerErrorPayload: Decodable {
    let error: String?
    let retryable: Bool?
}

final class AIInterviewerService {
    
    static let shared = AIInterviewerService()
    
    private init() {}
    
    private let functionURL =
    "https://lyxxusgyaqknqktljjbp.supabase.co/functions/v1/ai-interviewer"
    
    private let supabaseAnonKey =
    "sb_publishable__F3VyIpU8JdE8fGGd7y5nA_3hZ0bp35"
    
    func getNextQuestion(
        goal: String,
        deadline: String,
        availableHours: String,
        priority: String,
        previousAnswers: [QuestionAnswerRequest],
        previousQuestion: String?,
        userAnswer: String?
    ) async throws -> AIInterviewResponse {
        
        guard let url = URL(string: functionURL) else {
            throw AIInterviewerServiceError.invalidURL
        }
        
        let previousAnswersData: [[String: String]] = previousAnswers.map {
            [
                "question": $0.question,
                "answer": $0.answer
            ]
        }
        
        let requestBody: [String: Any] = [
            "goal": goal,
            "deadline": deadline,
            "availableHours": availableHours,
            "priority": priority,
            "previousAnswers": previousAnswersData,
            "previousQuestion": previousQuestion ?? "",
            "userAnswer": userAnswer ?? ""
        ]
        
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
        
        request.httpBody = try JSONSerialization.data(
            withJSONObject: requestBody
        )
        
        let (data, response) = try await URLSession.shared.data(
            for: request
        )
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIInterviewerServiceError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = Self.errorMessage(
                from: data,
                statusCode: httpResponse.statusCode
            )
            
            throw AIInterviewerServiceError.serverError(
                statusCode: httpResponse.statusCode,
                message: message
            )
        }
        
        do {
            return try JSONDecoder().decode(
                AIInterviewResponse.self,
                from: data
            )
        } catch {
            throw AIInterviewerServiceError.invalidData
        }
    }
    
    private static func errorMessage(
        from data: Data,
        statusCode: Int
    ) -> String {
        
        let payload = try? JSONDecoder().decode(
            AIInterviewerErrorPayload.self,
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
        
        return "The AI interviewer returned an error (HTTP \(statusCode))."
    }
}
