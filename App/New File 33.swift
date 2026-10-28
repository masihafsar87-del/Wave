import Foundation

enum PlanPersistenceStore {
    
    private static let planKey = "wave.savedPlan.v1"
    private static let completedTasksKey = "wave.completedTasks"
    
    static func loadPlan() -> AIPlan? {
        guard let data = UserDefaults.standard.data(
            forKey: planKey
        ) else {
            return nil
        }
        
        guard let plan = try? JSONDecoder().decode(
            AIPlan.self,
            from: data
        ), !plan.days.isEmpty else {
            return nil
        }
        
        return plan
    }
    
    static func savePlan(_ plan: AIPlan) {
        guard let data = try? encodedPlan(plan) else {
            return
        }
        
        let defaults = UserDefaults.standard
        let previousData = defaults.data(forKey: planKey)
        
        // A different plan starts with fresh task progress.
        // Saving the same plan preserves existing checkmarks.
        if previousData != data {
            defaults.removeObject(forKey: completedTasksKey)
        }
        
        defaults.set(data, forKey: planKey)
    }
    
    static func clearPlan() {
        let defaults = UserDefaults.standard
        
        defaults.removeObject(forKey: planKey)
        defaults.removeObject(forKey: completedTasksKey)
    }
    
    private static func encodedPlan(_ plan: AIPlan) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(plan)
    }
}
