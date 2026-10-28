import SwiftUI

struct ContentView: View {
    
    @State private var goal = ""
    @State private var deadline = Date()
    @State private var availableHours = ""
    @State private var priority = "High"
    @State private var showPlan = false
    
    @State private var savedPlan: AIPlan? =
    PlanPersistenceStore.loadPlan()
    
    let priorities = ["Low", "Medium", "High"]
    
    var body: some View {
        NavigationStack {
            Group {
                if let savedPlan {
                    PlanView(
                        plan: savedPlan,
                        resumeAtActiveTasks: true,
                        onStartNewPlan: {
                            PlanPersistenceStore.clearPlan()
                            
                            self.savedPlan = nil
                            goal = ""
                            deadline = Date()
                            availableHours = ""
                            priority = "High"
                            showPlan = false
                        }
                    )
                } else {
                    goalForm
                }
            }
        }
    }
    
    private var goalForm: some View {
        Form {
            Section("Your Goal") {
                TextField(
                    "What exactly do you want to accomplish?",
                    text: $goal
                )
            }
            
            Section("Deadline") {
                DatePicker(
                    "Deadline",
                    selection: $deadline,
                    displayedComponents: .date
                )
            }
            
            Section("Available Time") {
                TextField(
                    "Hours available per day",
                    text: $availableHours
                )
                .keyboardType(.decimalPad)
            }
            
            Section("Priority") {
                Picker("Priority", selection: $priority) {
                    ForEach(priorities, id: \.self) { item in
                        Text(item)
                    }
                }
            }
            
            Section {
                Button("Continue") {
                    generatePlan()
                    showPlan = true
                }
            }
        }
        .navigationTitle("AI Planner")
        .navigationDestination(isPresented: $showPlan) {
            InterviewView(
                goal: goal,
                deadline: deadline,
                availableHours: availableHours,
                priority: priority
            )
        }
    }
    
    private func generatePlan() {
        print("Goal: \(goal)")
        print("Deadline: \(deadline)")
        print("Available hours: \(availableHours)")
        print("Priority: \(priority)")
    }
}
