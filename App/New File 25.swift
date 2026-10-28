import SwiftUI

struct PlanReadyView: View {
    
    let understanding: AIUnderstandingResult
    
    @State private var generatedPlan: AIPlan?
    @State private var isGenerating = false
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            content
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if generatedPlan == nil &&
                !isGenerating &&
                errorMessage == nil {
                await generatePlan()
            }
        }
    }
    
    // MARK: - Main Content
    
    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 28) {
            if let plan = generatedPlan {
                readyContent(plan: plan)
            } else if isGenerating {
                loadingContent
            } else {
                errorContent
            }
        }
    }
    
    // MARK: - Ready Screen
    
    private func readyContent(plan: AIPlan) -> some View {
        VStack(alignment: .leading, spacing: 28) {
            readyHeader(plan: plan)
            overviewSection(plan: plan)
            strategySection(plan: plan)
            readyButton(plan: plan)
        }
    }
    
    private func readyHeader(plan: AIPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Plan Is Ready")
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(.primary)
            
            Text(plan.motivationalMessage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.blue)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private func overviewSection(plan: AIPlan) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("A plan built for you")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(plan.overview)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineSpacing(5)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private func strategySection(plan: AIPlan) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your way forward")
                .font(.system(size: 22, weight: .bold))
            
            Text(plan.strategy)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineSpacing(5)
            
            Text(
                """
                Your plan is based on your situation, your resources, \
                and the time available to you. Follow it consistently, \
                learn from your progress, and adjust when necessary. \
                No plan can guarantee success, but a realistic plan \
                and steady effort can help you move toward your goal.
                """
            )
            .font(.body)
            .foregroundStyle(.secondary)
            .lineSpacing(5)
        }
    }
    
    private func readyButton(plan: AIPlan) -> some View {
        VStack(spacing: 16) {
            Text("Are you ready to start?")
                .font(.system(size: 24, weight: .bold))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            
            NavigationLink {
                PlanView(plan: plan)
            } label: {
                Text("Ready")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.blue)
                    )
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Loading Screen
    
    private var loadingContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Building Your Plan")
                .font(.system(size: 34, weight: .bold))
            
            Text(
                """
                Wave is turning your goals, experience, available time, \
                and resources into a personalized plan.
                """
            )
            .font(.body)
            .foregroundStyle(.secondary)
            .lineSpacing(5)
            
            ProgressView("Creating your personalized plan...")
                .padding(.top, 8)
        }
    }
    
    // MARK: - Error Screen
    
    private var errorContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("We Couldn't Prepare Your Plan")
                .font(.system(size: 30, weight: .bold))
            
            Text(
                errorMessage ??
                "Something went wrong. Please try again."
            )
            .font(.body)
            .foregroundStyle(.secondary)
            
            Button {
                Task {
                    await generatePlan()
                }
            } label: {
                Text("Try Again")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.blue)
                    )
            }
        }
    }
    
    // MARK: - Generate Plan with Gemini
    
    @MainActor
    private func generatePlan() async {
        guard !isGenerating else {
            return
        }
        
        isGenerating = true
        errorMessage = nil
        
        defer {
            isGenerating = false
        }
        
        do {
            let plan = try await AIPlanningService.shared
                .generatePlan(from: understanding)
            
            generatedPlan = plan
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        PlanReadyView(
            understanding: AIUnderstandingResult(
                goal: "Improve my programming skills",
                currentSituation:
                    "I am a student beginning to build projects.",
                strengths: "Consistency and curiosity",
                weaknesses: "Limited practical experience",
                constraints: "Limited daily time",
                availableHours: "2 hours",
                deadline: Date(),
                priority: "High",
                originalInput: PlanInput(
                    goal: "Improve my programming skills",
                    deadline: Date(),
                    availableHours: "2 hours",
                    priority: "High",
                    answers: [],
                    correction: nil
                )
            )
        )
    }
}
