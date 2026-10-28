import Foundation

struct PlanningEngine {
    
    func createSteps(
        from strategy: StrategyResult,
        availableHours: String
    ) -> [PlanStep] {
        
        var steps: [PlanStep] = []
        
        for area in strategy.focusAreas {
            let step = PlanStep(
                title: area,
                description: "Work specifically on this area as part of your overall strategy.",
                duration: "20 minutes"
            )
            
            steps.append(step)
        }
        
        return steps
    }
}
