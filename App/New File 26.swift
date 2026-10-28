import Foundation

struct AIPlan: Codable {
    let motivationalMessage: String
    let overview: String
    let strategy: String
    let closingMessage: String
    let days: [AIPlanDay]
}

// Temporary sample data for developing the interface.
// We will replace this with the real Gemini-generated plan.
extension AIPlan {
    
    static var preview: AIPlan {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        
        func dateString(_ offset: Int) -> String {
            let date = calendar.date(
                byAdding: .day,
                value: offset,
                to: calendar.startOfDay(for: Date())
            ) ?? Date()
            
            return formatter.string(from: date)
        }
        
        return AIPlan(
            motivationalMessage:
                "Every focused session is a step toward becoming a better player.",
            
            overview:
                "This plan combines technical practice, fitness, recovery, and reflection. Each session has a specific purpose and builds toward your overall goal.",
            
            strategy:
                "Start with controlled movements, develop your skills progressively, and review your progress regularly. Adjust the workload when necessary.",
            
            closingMessage:
                "You have a direction. Now take it one day at a time, stay consistent, and let your progress build.",
            
            days: [
                
                AIPlanDay(
                    dayNumber: 1,
                    date: dateString(0),
                    focus: "First-touch control",
                    tasks: [
                        AIPlanTask(
                            title: "Improve first-touch control",
                            category: "Technical practice",
                            visualKey: "technical",
                            durationMinutes: 30,
                            description:
                                "Practise receiving the ball, controlling it into space, and preparing your next movement.",
                            instructions: [
                                "Warm up with gentle touches using both feet for 5 minutes.",
                                "Pass against a wall for 10 minutes. Receive each return and direct your first touch slightly to one side.",
                                "Set up two markers and practise controlling the ball toward each marker for 10 minutes.",
                                "Spend the final 5 minutes repeating comfortable passes and reviewing your control."
                            ],
                            benefit:
                                "A better first touch helps you retain possession, create space, and make your next decision faster."
                        ),
                        
                        AIPlanTask(
                            title: "Movement and mobility",
                            category: "Fitness",
                            visualKey: "fitness",
                            durationMinutes: 15,
                            description:
                                "Complete a short, comfortable movement session to prepare your body for training.",
                            instructions: [
                                "Begin with easy walking or marching.",
                                "Perform gentle, controlled hip and ankle movements.",
                                "Finish with light dynamic movements that feel comfortable."
                            ],
                            benefit:
                                "Comfortable movement preparation can help you get ready for training. Adapt the session to your ability and how you feel."
                        )
                    ]
                ),
                
                AIPlanDay(
                    dayNumber: 2,
                    date: dateString(1),
                    focus: "Passing and ball control",
                    tasks: [
                        AIPlanTask(
                            title: "Practise accurate passing",
                            category: "Skill practice",
                            visualKey: "practice",
                            durationMinutes: 25,
                            description:
                                "Focus on controlled passes and a first touch that prepares your next action.",
                            instructions: [
                                "Choose a safe space and a suitable target.",
                                "Practise short passes with your preferred foot.",
                                "Repeat using the other foot at a comfortable pace.",
                                "Finish by combining receiving, controlling, and passing."
                            ],
                            benefit:
                                "Consistent passing practice develops control and prepares you for faster combinations during play."
                        )
                    ]
                ),
                
                AIPlanDay(
                    dayNumber: 3,
                    date: dateString(2),
                    focus: "Review and recovery",
                    tasks: [
                        AIPlanTask(
                            title: "Review your progress",
                            category: "Review",
                            visualKey: "review",
                            durationMinutes: 10,
                            description:
                                "Reflect on what felt easier and what still needs attention.",
                            instructions: [
                                "Recall the previous sessions.",
                                "Write down one thing that improved.",
                                "Choose one skill to focus on next time."
                            ],
                            benefit:
                                "Review helps you notice progress and make future practice more purposeful."
                        ),
                        
                        AIPlanTask(
                            title: "Easy recovery session",
                            category: "Recovery",
                            visualKey: "recovery",
                            durationMinutes: 15,
                            description:
                                "Take time for comfortable, low-intensity movement and recovery.",
                            instructions: [
                                "Walk gently or do another comfortable low-intensity activity.",
                                "Move through a few gentle mobility exercises.",
                                "Stop or modify anything that causes pain or discomfort."
                            ],
                            benefit:
                                "Balancing practice with recovery helps you maintain a sustainable routine."
                        )
                    ]
                ),
                
                AIPlanDay(
                    dayNumber: 4,
                    date: dateString(3),
                    focus: "Technique development",
                    tasks: [
                        AIPlanTask(
                            title: "Practise receiving under control",
                            category: "Technical practice",
                            visualKey: "technical",
                            durationMinutes: 25,
                            description:
                                "Repeat controlled receiving drills and vary the direction of your first touch.",
                            instructions: [
                                "Begin with easy passes against a wall.",
                                "Alternate the direction of your first touch.",
                                "Focus on control before increasing your pace."
                            ],
                            benefit:
                                "Gradually adding variation helps you apply a familiar skill in more situations."
                        )
                    ]
                ),
                
                AIPlanDay(
                    dayNumber: 5,
                    date: dateString(4),
                    focus: "Review and learning",
                    tasks: [
                        AIPlanTask(
                            title: "Review your technique",
                            category: "Review",
                            visualKey: "review",
                            durationMinutes: 15,
                            description:
                                "Think about your recent sessions and identify your next improvement.",
                            instructions: [
                                "Review your notes or training observations.",
                                "Identify a recurring difficulty.",
                                "Choose one practical adjustment for your next session."
                            ],
                            benefit:
                                "Small, informed adjustments help you keep learning instead of repeating the same approach indefinitely."
                        )
                    ]
                ),
                
                AIPlanDay(
                    dayNumber: 6,
                    date: dateString(5),
                    focus: "Practice and consistency",
                    tasks: [
                        AIPlanTask(
                            title: "Combine your core skills",
                            category: "Skill practice",
                            visualKey: "practice",
                            durationMinutes: 30,
                            description:
                                "Combine receiving, movement, and passing in one controlled session.",
                            instructions: [
                                "Warm up with simple ball touches.",
                                "Practise receiving and passing against a target.",
                                "Introduce movement between repetitions.",
                                "Finish by reviewing your control and accuracy."
                            ],
                            benefit:
                                "Combining skills helps you practise using them together rather than in isolation."
                        )
                    ]
                ),
                
                AIPlanDay(
                    dayNumber: 7,
                    date: dateString(6),
                    focus: "Weekly reflection",
                    tasks: [
                        AIPlanTask(
                            title: "Review your week",
                            category: "Planning",
                            visualKey: "planning",
                            durationMinutes: 10,
                            description:
                                "Look back at your sessions and prepare for the following week.",
                            instructions: [
                                "List the sessions you completed.",
                                "Identify one strength and one area to improve.",
                                "Decide what deserves more attention next week."
                            ],
                            benefit:
                                "Regular reflection helps you make your next week more relevant to your progress."
                        )
                    ]
                )
            ]
        )
    }
}
