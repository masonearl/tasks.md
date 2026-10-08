import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // App Icon
            #if os(macOS)
            if let appIcon = NSImage(named: "AppIcon") {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 128, height: 128)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(radius: 4)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .frame(width: 128, height: 128)
                    .foregroundStyle(.blue)
            }
            #else
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 128, height: 128)
                .foregroundStyle(.blue)
            #endif
            
            // App Name and Version
            VStack(spacing: 8) {
                Text("tasks.md")
                    .font(.system(size: 32, weight: .semibold))
                
                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                   let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                    Text("Version \(version) (\(build))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Description
            Text("Your markdown task manager")
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
            
            Divider()
                .padding(.vertical, 8)
            
            // Links
            VStack(spacing: 12) {
                Button("GitHub") {
                    if let url = URL(string: "https://github.com/masonearl/tasks.md") {
                        #if os(macOS)
                        NSWorkspace.shared.open(url)
                        #else
                        UIApplication.shared.open(url)
                        #endif
                    }
                }
                #if os(macOS)
                .buttonStyle(.link)
                #else
                .buttonStyle(.bordered)
                #endif
                
                Text("© 2026 Mason Earl")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
                .frame(height: 20)
            
            // Close Button
            Button("Close") {
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
            .controlSize(.large)
        }
        .padding(32)
        .frame(width: 400, height: 500)
        #if os(macOS)
        .background(Color(NSColor.windowBackgroundColor))
        #else
        .background(Color(UIColor.systemBackground))
        #endif
    }
}

#Preview {
    AboutView()
}

