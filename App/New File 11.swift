import Foundation

struct AIUnderstandingResult {
    let goal: String
    let currentSituation: String
    let strengths: String
    let weaknesses: String
    let constraints: String
    let availableHours: String
    let deadline: Date
    let priority: String
    
    let originalInput: PlanInput
}
