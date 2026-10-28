import Foundation

struct AIPlanDay: Codable, Identifiable {
    let dayNumber: Int
    
    // Format: yyyy-MM-dd
    let date: String
    
    let focus: String
    let tasks: [AIPlanTask]
    
    var id: String { date }
}
