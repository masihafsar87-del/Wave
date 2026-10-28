import Foundation

struct AnalysisEngine {
    
    func analyze(_ planInput: PlanInput) -> AnalysisResult {
        
        var currentSituation = "Not enough information yet."
        var strengths = "Not enough information yet."
        var weaknesses = "Not enough information yet."
        
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
            }
        }
        
        return AnalysisResult(
            goal: planInput.goal,
            currentSituation: currentSituation,
            strengths: strengths,
            weaknesses: weaknesses,
            constraints: "Available time: \(planInput.availableHours) hours/day",
            priority: planInput.priority,
            availableHours: planInput.availableHours
        )
    }
}
