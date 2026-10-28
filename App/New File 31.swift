import Foundation

enum AIPlanningServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(String)
    case invalidPlan
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The AI planning service URL is invalid."
            
        case .invalidResponse:
            return "Wave couldn't read the AI planning service's response. Please try again."
            
        case .serverError(let message):
            return message
            
        case .invalidPlan:
            return "The AI returned a plan that Wave couldn't read. Please try again."
        }
    }
}

private struct AIPlanningErrorPayload: Decodable {
    let error: String?
    let retryable: Bool?
}

final class AIPlanningService {
    
    static let shared = AIPlanningService()
    
    private init() {}
    
    private let functionURL =
    "https://lyxxusgyaqknqktljjbp.supabase.co/functions/v1/ai-final-planner"
    
    private let supabaseAnonKey =
    "sb_publishable__F3VyIpU8JdE8fGGd7y5nA_3hZ0bp35"
    
    func generatePlan(
        from understanding: AIUnderstandingResult
    ) async throws -> AIPlan {
        
        guard let url = URL(string: functionURL) else {
            throw AIPlanningServiceError.invalidURL
        }
        
        let input = understanding.originalInput
        
        let requestBody = AIPlanGenerationRequest(
            goal: understanding.goal,
            startDate: Self.formatDate(Date()),
            deadline: Self.formatDate(understanding.deadline),
            availableHours: understanding.availableHours,
            priority: understanding.priority,
            answers: input.answers.map {
                AIPlanGenerationAnswer(
                    question: $0.question,
                    answer: $0.answer
                )
            },
            correction: input.correction,
            understanding: AIPlanGenerationUnderstanding(
                goal: understanding.goal,
                currentSituation: understanding.currentSituation,
                strengths: understanding.strengths,
                weaknesses: understanding.weaknesses,
                constraints: understanding.constraints
            )
        )
        
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
            throw AIPlanningServiceError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = Self.errorMessage(
                from: data,
                statusCode: httpResponse.statusCode
            )
            
            throw AIPlanningServiceError.serverError(message)
        }
        
        do {
            let plan = try JSONDecoder().decode(
                AIPlan.self,
                from: data
            )
            
            guard !plan.days.isEmpty else {
                throw AIPlanningServiceError.invalidPlan
            }
            
            return plan
            
        } catch let error as AIPlanningServiceError {
            throw error
            
        } catch {
            throw AIPlanningServiceError.invalidPlan
        }
    }
    
    private static func errorMessage(
        from data: Data,
        statusCode: Int
    ) -> String {
        
        let payload = try? JSONDecoder().decode(
            AIPlanningErrorPayload.self,
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
        
        return "The AI planning service returned an error (HTTP \(statusCode))."
    }
    
    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar.current
        formatter.timeZone = Calendar.current.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        
        return formatter.string(from: date)
    }
}
