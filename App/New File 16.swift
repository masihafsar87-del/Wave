import SwiftUI

struct UnderstandingView: View {
    
    let result: AIUnderstandingResult
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // MARK: - Title
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Here's what I understood")
                        .font(.system(size: 32, weight: .bold))
                    
                    Text("Take a moment to make sure this looks right.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                
                // MARK: - Goal
                
                UnderstandingSection(
                    title: "Goal",
                    content: result.goal
                )
                
                // MARK: - Current Situation
                
                UnderstandingSection(
                    title: "Current Situation",
                    content: result.currentSituation
                )
                
                // MARK: - Strengths
                
                UnderstandingSection(
                    title: "Strengths",
                    content: result.strengths
                )
                
                // MARK: - Weaknesses
                
                UnderstandingSection(
                    title: "Areas to Improve",
                    content: result.weaknesses
                )
                
                // MARK: - Constraints
                
                UnderstandingSection(
                    title: "Constraints",
                    content: result.constraints
                )
                
                // MARK: - Plan Details
                
                VStack(alignment: .leading, spacing: 14) {
                    Text("Plan Details")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Available Time")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text(result.availableHours)
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Priority")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text(result.priority)
                                .font(.body)
                                .fontWeight(.medium)
                        }
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Deadline")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(
                            result.deadline.formatted(
                                date: .long,
                                time: .omitted
                            )
                        )
                        .font(.body)
                        .fontWeight(.medium)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.secondarySystemBackground))
                )
                
                // MARK: - Buttons
                
                VStack(spacing: 14) {
                    
                    NavigationLink {
                        PlanReadyView(understanding: result)
                    } label: {
                        Text("Looks Good — Build My Plan")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.blue)
                            )
                    }
                    
                    NavigationLink {
                        CorrectionView(result: result)
                    } label: {
                        Text("Something Is Wrong")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.blue, lineWidth: 1.5)
                            )
                    }
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
        .navigationTitle("Understanding")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Reusable Section

struct UnderstandingSection: View {
    
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(content)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    NavigationStack {
        UnderstandingView(
            result: AIUnderstandingResult(
                goal: "Improve my programming skills before university",
                currentSituation: "I am a student with some programming experience.",
                strengths: "Consistency and curiosity",
                weaknesses: "Limited practical project experience",
                constraints: "Limited daily time",
                availableHours: "2 hours",
                deadline: Date(),
                priority: "High",
                originalInput: PlanInput(
                    goal: "Improve my programming skills before university",
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
