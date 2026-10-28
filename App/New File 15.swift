import SwiftUI

struct SafetyView: View {
    let message: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            Text("Let's pause here.")
                .font(.largeTitle)
                .bold()
            
            Text(message)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Safety")
    }
}
