import Foundation

struct AIPlannerResponse: Codable {
    
    let goal: String
    
    let currentSituation: String
    
    let strengths: [String]
    
    let weaknesses: [String]
    
    let constraints: [String]
    
    let reasoning: String
    
}
