import SwiftUI

struct AnalysisView: View {
    let planInput: PlanInput
    
    var analysis: AnalysisResult {
        AnalysisEngine().analyze(planInput)
    }
    
    var strategy: StrategyResult {
        StrategyEngine().createStrategy(from: analysis)
    }
    
    var planSteps: [PlanStep] {
        PlanningEngine().createSteps(
            from: strategy,
            availableHours: analysis.availableHours
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                Text("Here's what I've understood so far.")
                    .font(.headline)
                
                Text("Goal")
                    .font(.title2)
                    .bold()
                
                Text(analysis.goal)
                
                Text("Current Situation")
                    .font(.title2)
                    .bold()
                
                Text(analysis.currentSituation)
                
                Text("Strengths")
                    .font(.title2)
                    .bold()
                
                Text(analysis.strengths)
                
                Text("Weaknesses")
                    .font(.title2)
                    .bold()
                
                Text(analysis.weaknesses)
                
                Text("Constraints")
                    .font(.title2)
                    .bold()
                
                Text(analysis.constraints)
                
                Divider()
                
                Text("Strategy")
                    .font(.title)
                    .bold()
                
                Text(strategy.mainStrategy)
                    .font(.headline)
                
                Text("Focus Areas")
                    .font(.title2)
                    .bold()
                
                ForEach(strategy.focusAreas, id: \.self) { area in
                    Text("• \(area)")
                }
                
                Text("Why?")
                    .font(.title2)
                    .bold()
                
                Text(strategy.reasoning)
                
                Divider()
                
                Text("Plan Steps")
                    .font(.title)
                    .bold()
                
                ForEach(planSteps, id: \.title) { step in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(step.title)
                            .font(.headline)
                        
                        Text(step.description)
                        
                        Text("Duration: \(step.duration)")
                            .font(.subheadline)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Analysis")
    }
}

#Preview {
    AnalysisView(
        planInput: PlanInput(
            goal: "Make my university football team",
            deadline: Date(),
            availableHours: "1.5",
            priority: "High",
            answers: [
                QuestionAnswer(
                    question: "What position do you play?",
                    answer: "I play winger."
                ),
                QuestionAnswer(
                    question: "What do you consider your strongest part of your game?",
                    answer: "Speed and dribbling."
                ),
                QuestionAnswer(
                    question: "What part of your game needs improvement?",
                    answer: "My left foot and finishing."
                )
            ],
            correction: nil
        )
    )
}
