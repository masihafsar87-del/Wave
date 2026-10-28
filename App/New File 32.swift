
import Foundation
import SwiftUI

@MainActor
final class PlanProgressStore: ObservableObject {
    @Published private(set) var completedTasks: Set<String> = []
    
    private let storageKey = "wave.completedTasks"
    
    init() {
        loadProgress()
    }
    
    func isCompleted(_ taskID: String) -> Bool {
        completedTasks.contains(taskID)
    }
    
    func toggle(_ taskID: String) {
        if completedTasks.contains(taskID) {
            completedTasks.remove(taskID)
        } else {
            completedTasks.insert(taskID)
        }
        
        saveProgress()
    }
    
    func completedCount(for taskIDs: [String]) -> Int {
        taskIDs.filter { completedTasks.contains($0) }.count
    }
    
    func resetProgress() {
        completedTasks.removeAll()
        saveProgress()
    }
    
    private func loadProgress() {
        let savedIDs = UserDefaults.standard.stringArray(
            forKey: storageKey
        ) ?? []
        
        completedTasks = Set(savedIDs)
    }
    
    private func saveProgress() {
        UserDefaults.standard.set(
            Array(completedTasks),
            forKey: storageKey
        )
    }
}
