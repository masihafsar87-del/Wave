import Foundation

struct AIUnderstandingEngine {
    
    func understand(_ planInput: PlanInput) -> AIUnderstandingResult {
        
        var currentSituation = "No information provided."
        var strengths = "No information provided."
        var weaknesses = "No information provided."
        var constraints = "No additional constraints provided."
        
        for item in planInput.answers {
            let question = item.question.lowercased()
            
            if question.contains("current") ||
                question.contains("experience") ||
                question.contains("level") {
                
                currentSituation = item.answer
                
            } else if question.contains("strongest") ||
                        question.contains("strength") {
                
                strengths = item.answer
                
            } else if question.contains("weakness") ||
                        question.contains("improvement") ||
                        question.contains("difficult") {
                
                weaknesses = item.answer
                
            } else if question.contains("limitation") ||
                        question.contains("constraint") {
                
                constraints = item.answer
            }
        }
        
        return AIUnderstandingResult(
            goal: planInput.goal,
            currentSituation: currentSituation,
            strengths: strengths,
            weaknesses: weaknesses,
            constraints: constraints,
            availableHours: planInput.availableHours,
            deadline: planInput.deadline,
            priority: planInput.priority,
            originalInput: planInput
        )
    }
}
