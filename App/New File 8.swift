import Foundation

struct StrategyEngine {
    
    func createStrategy(from analysis: AnalysisResult) -> StrategyResult {
        
        return StrategyResult(
            mainStrategy: "Focus your available time on the areas that will have the greatest impact on your goal.",
            
            focusAreas: [
                analysis.weaknesses,
                analysis.strengths
            ],
            
            reasoning: "The strategy is based on your goal, current situation, strengths, weaknesses, available time, and priority."
        )
    }
}
