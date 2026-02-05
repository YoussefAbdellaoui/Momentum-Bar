import SwiftUI

struct AnnouncementModalView: View {
    let announcement: Announcement
    let onDismiss: () -> Void
    let onPrimaryAction: (() -> Void)?

    private var accentColor: Color {
        switch announcement.type {
        case .info:
            return .accentColor
        case .warning:
            return .orange
        case .critical:
            return .red
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 36))
                    .foregroundStyle(accentColor)

                Text(announcement.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(announcement.body)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            Divider()

            HStack(spacing: 12) {
                Button("Dismiss") {
                    onDismiss()
                }
                .buttonStyle(.bordered)

                if let onPrimaryAction {
                    Button("Learn More") {
                        onPrimaryAction()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(24)
        .frame(width: 420)
    }
}
