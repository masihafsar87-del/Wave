import Foundation

struct AIPlanGenerationRequest: Encodable {
    let goal: String
    let startDate: String
    let deadline: String
    let availableHours: String
    let priority: String
    let answers: [AIPlanGenerationAnswer]
    let correction: String?
    let understanding: AIPlanGenerationUnderstanding
}

struct AIPlanGenerationAnswer: Encodable {
    let question: String
    let answer: String
}

struct AIPlanGenerationUnderstanding: Encodable {
    let goal: String
    let currentSituation: String
    let strengths: String
    let weaknesses: String
    let constraints: String
}
