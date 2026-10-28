import Foundation

struct SafetyEngine {
    
    func check(_ planInput: PlanInput) -> SafetyResult {
        
        let goalText = planInput.goal.lowercased()
        
        let answerText = planInput.answers
            .map { $0.answer.lowercased() }
            .joined(separator: " ")
        
        let correctionText =
        planInput.correction?.lowercased() ?? ""
        
        let textToCheck =
        goalText + " " + answerText + " " + correctionText
        
        let unsafeTopics: [String] = [
            "suicide",
            "kill myself",
            "self harm",
            "self-harm",
            "harm myself",
            "murder",
            "make a bomb",
            "build a bomb"
        ]
        
        for topic in unsafeTopics {
            
            if textToCheck.contains(topic) {
                
                return SafetyResult(
                    isSafe: false,
                    message:
                        "This goal isn't something I can help plan."
                )
            }
        }
        
        return SafetyResult(
            isSafe: true,
            message: "The request can continue to the AI safety check."
        )
    }
}
