import Foundation

struct AIPlannerRequest: Codable {
    let goal: String
    let deadline: String
    let availableHours: String
    let priority: String
    let answers: [QuestionAnswerRequest]
    let correction: String?
    let currentUnderstanding: AIUnderstandingContext?
}

struct QuestionAnswerRequest: Codable {
    let question: String
    let answer: String
}

struct AIUnderstandingContext: Codable {
    let goal: String
    let currentSituation: String
    let strengths: String
    let weaknesses: String
    let constraints: String
}
