import SwiftUI

struct CorrectionView: View {
    
    let result: AIUnderstandingResult
    
    @State private var correction = ""
    
    @State private var correctedResult: AIUnderstandingResult?
    
    @State private var showUpdatedUnderstanding = false
    
    @State private var isLoading = false
    
    @State private var showError = false
    @State private var errorMessage = ""
    
    @State private var safetyBlocked = false
    @State private var safetyMessage = ""
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 20) {
            
            Text("What did I get wrong?")
                .font(.largeTitle)
                .bold()
            
            Text(
                "Tell me what you'd like to correct, and I'll update my understanding."
            )
            
            TextField(
                "Tell me what I misunderstood...",
                text: $correction,
                axis: .vertical
            )
            .lineLimit(6, reservesSpace: true)
            
            Button(
                isLoading
                ? "Updating..."
                : "Submit Correction"
            ) {
                submitCorrection()
            }
            .buttonStyle(.borderedProminent)
            .disabled(
                correction.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ).isEmpty
                || isLoading
            )
            
            Spacer()
        }
        .padding()
        .navigationTitle("Correction")
        
        .navigationDestination(
            isPresented: $showUpdatedUnderstanding
        ) {
            if let correctedResult {
                UnderstandingView(
                    result: correctedResult
                )
            }
        }
        
        .navigationDestination(
            isPresented: $safetyBlocked
        ) {
            SafetyView(
                message: safetyMessage
            )
        }
        
        .alert(
            "Correction Error",
            isPresented: $showError
        ) {
            Button("OK") {
                showError = false
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func submitCorrection() {
        
        let trimmedCorrection =
        correction.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        
        guard !trimmedCorrection.isEmpty else {
            return
        }
        
        isLoading = true
        
        let input = result.originalInput
        
        let safetyInput = PlanInput(
            goal: input.goal,
            deadline: input.deadline,
            availableHours: input.availableHours,
            priority: input.priority,
            answers: input.answers,
            correction: trimmedCorrection
        )
        
        // ---------------------------------------------------------
        // 1. LOCAL SAFETY CHECK
        // ---------------------------------------------------------
        
        let localSafetyResult =
        SafetyEngine().check(safetyInput)
        
        if !localSafetyResult.isSafe {
            
            safetyMessage = localSafetyResult.message
            safetyBlocked = true
            isLoading = false
            return
        }
        
        Task {
            
            do {
                
                // -------------------------------------------------
                // 2. AI SAFETY CHECK
                // -------------------------------------------------
                
                let safetyAnswers =
                input.answers.map {
                    QuestionAnswerRequest(
                        question: $0.question,
                        answer: $0.answer
                    )
                }
                
                let aiSafetyResult =
                try await AISafetyService.shared.check(
                    goal: input.goal,
                    answers: safetyAnswers,
                    correction: trimmedCorrection
                )
                
                if !aiSafetyResult.isSafe {
                    
                    safetyMessage = aiSafetyResult.message
                    safetyBlocked = true
                    isLoading = false
                    return
                }
                
                // -------------------------------------------------
                // 3. AI RE-UNDERSTANDING
                // -------------------------------------------------
                
                let request = AIPlannerRequest(
                    goal: input.goal,
                    deadline: input.deadline.formatted(
                        date: .long,
                        time: .omitted
                    ),
                    availableHours: input.availableHours,
                    priority: input.priority,
                    answers: safetyAnswers,
                    correction: trimmedCorrection,
                    currentUnderstanding:
                        AIUnderstandingContext(
                            goal: result.goal,
                            currentSituation:
                                result.currentSituation,
                            strengths: result.strengths,
                            weaknesses: result.weaknesses,
                            constraints: result.constraints
                        )
                )
                
                let response =
                try await AIPlannerService.shared
                    .generateUnderstanding(
                        from: request
                    )
                
                let updatedInput = PlanInput(
                    goal: input.goal,
                    deadline: input.deadline,
                    availableHours: input.availableHours,
                    priority: input.priority,
                    answers: input.answers,
                    correction: trimmedCorrection
                )
                
                correctedResult =
                AIUnderstandingResult(
                    goal: response.goal,
                    currentSituation:
                        response.currentSituation,
                    strengths:
                        response.strengths.joined(
                            separator: "\n• "
                        ),
                    weaknesses:
                        response.weaknesses.joined(
                            separator: "\n• "
                        ),
                    constraints:
                        response.constraints.joined(
                            separator: "\n• "
                        ),
                    availableHours:
                        input.availableHours,
                    deadline: input.deadline,
                    priority: input.priority,
                    originalInput: updatedInput
                )
                
                isLoading = false
                showUpdatedUnderstanding = true
                
            } catch {
                
                isLoading = false
                errorMessage =
                error.localizedDescription
                showError = true
            }
        }
    }
}
