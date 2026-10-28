import Foundation

struct PlanInput {
    let goal: String
    let deadline: Date
    let availableHours: String
    let priority: String
    let answers: [QuestionAnswer]
    let correction: String?
}
