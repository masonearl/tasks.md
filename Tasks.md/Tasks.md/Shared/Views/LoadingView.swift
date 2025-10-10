import SwiftUI

struct LoadingView: View {
    @State private var animate1 = false
    @State private var animate2 = false
    @State private var animate3 = false
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                Circle()
                    .fill(.blue)
                    .frame(width: 20, height: 20)
                    .scaleEffect(animate1 ? 1.2 : 0.8)
                    .opacity(animate1 ? 1 : 0.5)
                
                Circle()
                    .fill(.blue)
                    .frame(width: 20, height: 20)
                    .scaleEffect(animate2 ? 1.2 : 0.8)
                    .opacity(animate2 ? 1 : 0.5)
                
                Circle()
                    .fill(.blue)
                    .frame(width: 20, height: 20)
                    .scaleEffect(animate3 ? 1.2 : 0.8)
                    .opacity(animate3 ? 1 : 0.5)
            }
            
            Text("Loading tasks...")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                animate1 = true
            }
            withAnimation(.easeInOut(duration: 0.4).delay(0.15).repeatForever(autoreverses: true)) {
                animate2 = true
            }
            withAnimation(.easeInOut(duration: 0.4).delay(0.3).repeatForever(autoreverses: true)) {
                animate3 = true
            }
        }
    }
}





