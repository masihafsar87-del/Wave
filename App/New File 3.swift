import SwiftUI

private enum InterviewViewError: LocalizedError {
    case emptyQuestion
    
    var errorDescription: String? {
        switch self {
        case .emptyQuestion:
            return "The AI interviewer returned an empty question. Please try again."
        }
    }
}

struct InterviewView: View {
    
    let goal: String
    let deadline: Date
    let availableHours: String
    let priority: String
    
    @State private var answer = ""
    @State private var previousQuestion: String?
    @State private var answers: [QuestionAnswer] = []
    
    @State private var currentQuestion = ""
    @State private var isLoading = true
    @State private var isSubmitting = false
    
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var canRetryStart = false
    
    @State private var safetyBlocked = false
    @State private var safetyMessage = ""
    
    @State private var showUnderstanding = false
    @State private var understandingResult: AIUnderstandingResult?
    
    // Holds the completed interview while the understanding step is retried.
    @State private var pendingFinalizationAnswers: [QuestionAnswer]?
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 20) {
            
            Text("Let's understand your goal.")
                .font(.largeTitle)
                .bold()
            
            Text(
                "I'll ask questions based on your answers so I can understand your situation properly before building your plan."
            )
            
            Divider()
            
            if isLoading {
                
                ProgressView("Thinking...")
                
            } else if let pendingAnswers = pendingFinalizationAnswers {
                
                Text("Your interview is complete.")
                    .font(.headline)
                
                Text(
                    "Wave couldn't finish preparing your understanding yet. Your answers are preserved."
                )
                
                Button("Retry Understanding") {
                    retryFinalization(using: pendingAnswers)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSubmitting)
                
            } else if currentQuestion.isEmpty {
                
                Text("The interview hasn't started yet.")
                    .font(.headline)
                
                Button("Try Again") {
                    Task {
                        await startInterview()
                    }
                }
                .buttonStyle(.borderedProminent)
                
            } else {
                
                Text("AI Interviewer")
                    .font(.headline)
                
                Text(currentQuestion)
                    .font(.title3)
                    .bold()
                
                TextField(
                    "Type your answer...",
                    text: $answer,
                    axis: .vertical
                )
                .lineLimit(6, reservesSpace: true)
                
                Button(
                    isSubmitting ? "Thinking..." : "Continue"
                ) {
                    submitAnswer()
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    answer.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty || isSubmitting
                )
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("AI Interview")
        .task {
            await startInterview()
        }
        .navigationDestination(isPresented: $showUnderstanding) {
            if let understandingResult {
                UnderstandingView(result: understandingResult)
            }
        }
        .navigationDestination(isPresented: $safetyBlocked) {
            SafetyView(message: safetyMessage)
        }
        .alert(
            "AI Planner Error",
            isPresented: $showError
        ) {
            if canRetryStart {
                Button("Try Again") {
                    showError = false
                    
                    Task {
                        await startInterview()
                    }
                }
            }
            
            Button("OK") {
                showError = false
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Start Interview
    
    private func startInterview() async {
        
        isLoading = true
        isSubmitting = false
        canRetryStart = false
        
        do {
            // Check the original goal before asking Gemini
            // to generate even the first interview question.
            let safetyResult = try await evaluateSafety(for: [])
            
            guard safetyResult.isSafe else {
                blockForSafety(safetyResult.message)
                isLoading = false
                return
            }
            
            let response = try await AIInterviewerService.shared.getNextQuestion(
                goal: goal,
                deadline: formattedDeadline,
                availableHours: availableHours,
                priority: priority,
                previousAnswers: [],
                previousQuestion: nil,
                userAnswer: nil
            )
            
            if response.finished {
                pendingFinalizationAnswers = []
                await finishInterview(using: [])
                return
            }
            
            guard !response.question
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty else {
                throw InterviewViewError.emptyQuestion
            }
            
            currentQuestion = response.question
            previousQuestion = response.question
            isLoading = false
            
        } catch {
            isLoading = false
            canRetryStart = true
            showErrorMessage(error)
        }
    }
    
    // MARK: - Submit Answer
    
    private func submitAnswer() {
        
        guard !isSubmitting else {
            return
        }
        
        let trimmedAnswer = answer.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        
        guard !trimmedAnswer.isEmpty else {
            return
        }
        
        isSubmitting = true
        
        let questionAnswer = QuestionAnswer(
            question: currentQuestion,
            answer: trimmedAnswer
        )
        
        // Do not commit the new answer to state yet.
        // It is committed only after the next question is received.
        let updatedAnswers = answers + [questionAnswer]
        
        Task {
            await askAIForNextQuestion(
                updatedAnswers: updatedAnswers,
                userAnswer: trimmedAnswer
            )
        }
    }
    
    // MARK: - Continue Interview
    
    private func askAIForNextQuestion(
        updatedAnswers: [QuestionAnswer],
        userAnswer: String
    ) async {
        
        do {
            // The local and AI safety checks must both pass.
            let safetyResult = try await evaluateSafety(
                for: updatedAnswers
            )
            
            guard safetyResult.isSafe else {
                blockForSafety(safetyResult.message)
                isSubmitting = false
                isLoading = false
                return
            }
            
            let safetyAnswers = makeSafetyAnswers(from: updatedAnswers)
            
            let response = try await AIInterviewerService.shared.getNextQuestion(
                goal: goal,
                deadline: formattedDeadline,
                availableHours: availableHours,
                priority: priority,
                previousAnswers: safetyAnswers,
                previousQuestion: previousQuestion,
                userAnswer: userAnswer
            )
            
            if response.finished {
                // Preserve the completed interview for a dedicated retry
                // if the understanding generation fails.
                pendingFinalizationAnswers = updatedAnswers
                
                await finishInterview(using: updatedAnswers)
                return
            }
            
            guard !response.question
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty else {
                throw InterviewViewError.emptyQuestion
            }
            
            // Commit the answer only after getting the next question.
            // If a request failed, the user can try again without duplicates.
            answers = updatedAnswers
            currentQuestion = response.question
            previousQuestion = response.question
            answer = ""
            
            isSubmitting = false
            isLoading = false
            
        } catch {
            isSubmitting = false
            isLoading = false
            showErrorMessage(error)
        }
    }
    
    // MARK: - Finish Interview
    
    private func finishInterview(
        using interviewAnswers: [QuestionAnswer]
    ) async {
        
        isLoading = true
        
        let planInput = makePlanInput(from: interviewAnswers)
        
        do {
            // Final safety check immediately before AI understanding.
            let safetyResult = try await evaluateSafety(
                for: interviewAnswers
            )
            
            guard safetyResult.isSafe else {
                pendingFinalizationAnswers = nil
                blockForSafety(safetyResult.message)
                isLoading = false
                isSubmitting = false
                return
            }
            
            let safetyAnswers = makeSafetyAnswers(
                from: interviewAnswers
            )
            
            let request = AIPlannerRequest(
                goal: goal,
                deadline: formattedDeadline,
                availableHours: availableHours,
                priority: priority,
                answers: safetyAnswers,
                correction: nil,
                currentUnderstanding: nil
            )
            
            let response = try await AIPlannerService.shared.generateUnderstanding(
                from: request
            )
            
            // Preserve exactly the answers used for understanding.
            answers = interviewAnswers
            
            understandingResult = AIUnderstandingResult(
                goal: response.goal,
                currentSituation: response.currentSituation,
                strengths: response.strengths.joined(
                    separator: "\n• "
                ),
                weaknesses: response.weaknesses.joined(
                    separator: "\n• "
                ),
                constraints: response.constraints.joined(
                    separator: "\n• "
                ),
                availableHours: availableHours,
                deadline: deadline,
                priority: priority,
                originalInput: planInput
            )
            
            pendingFinalizationAnswers = nil
            isLoading = false
            isSubmitting = false
            showUnderstanding = true
            
        } catch {
            // Keep the completed interview so retrying this step does not
            // submit the last answer to the interviewer a second time.
            pendingFinalizationAnswers = interviewAnswers
            
            isLoading = false
            isSubmitting = false
            showErrorMessage(error)
        }
    }
    
    private func retryFinalization(
        using interviewAnswers: [QuestionAnswer]
    ) {
        guard !isSubmitting && !isLoading else {
            return
        }
        
        Task {
            await finishInterview(using: interviewAnswers)
        }
    }
    
    // MARK: - Safety
    
    private func evaluateSafety(
        for interviewAnswers: [QuestionAnswer]
    ) async throws -> (isSafe: Bool, message: String) {
        
        let planInput = makePlanInput(from: interviewAnswers)
        
        // First: local safety check.
        let localResult = SafetyEngine().check(planInput)
        
        guard localResult.isSafe else {
            return (
                isSafe: false,
                message: localResult.message
            )
        }
        
        // Second: backend AI safety check.
        // If it throws, the error propagates and the caller must stop.
        let aiResult = try await AISafetyService.shared.check(
            goal: goal,
            answers: makeSafetyAnswers(from: interviewAnswers),
            correction: nil
        )
        
        return (
            isSafe: aiResult.isSafe,
            message: aiResult.message
        )
    }
    
    private func blockForSafety(_ message: String) {
        safetyMessage = message
        safetyBlocked = true
    }
    
    // MARK: - Helpers
    
    private var formattedDeadline: String {
        deadline.formatted(
            date: .long,
            time: .omitted
        )
    }
    
    private func makePlanInput(
        from interviewAnswers: [QuestionAnswer]
    ) -> PlanInput {
        
        PlanInput(
            goal: goal,
            deadline: deadline,
            availableHours: availableHours,
            priority: priority,
            answers: interviewAnswers,
            correction: nil
        )
    }
    
    private func makeSafetyAnswers(
        from interviewAnswers: [QuestionAnswer]
    ) -> [QuestionAnswerRequest] {
        
        interviewAnswers.map {
            QuestionAnswerRequest(
                question: $0.question,
                answer: $0.answer
            )
        }
    }
    
    private func showErrorMessage(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
}
