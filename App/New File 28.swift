import Foundation

struct AIPlanTask: Codable, Identifiable {
    let title: String
    
    // Human-readable category generated for the task.
    let category: String
    
    // A supported key such as technical, fitness, or recovery.
    let visualKey: String
    
    let durationMinutes: Int?
    
    // What the task involves.
    let description: String
    
    // Practical instructions in the order they should be done.
    let instructions: [String]
    
    // Why the task helps achieve the goal.
    let benefit: String
    
    var id: String {
        "\(visualKey)-\(title)"
    }
}
