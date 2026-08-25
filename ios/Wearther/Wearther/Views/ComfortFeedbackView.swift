import SwiftUI

struct ComfortFeedbackView: View {
    let lastFeedback: ComfortFeedback?
    let onFeedback: (ComfortFeedback) -> Void

    private struct Option: Identifiable {
        let id: ComfortFeedback
        let emoji: String
        let label: String
    }

    private let options: [Option] = [
        .init(id: .tooCold, emoji: "🥶", label: "Too Cold"),
        .init(id: .perfect, emoji: "🙂", label: "Perfect"),
        .init(id: .tooHot, emoji: "🥵", label: "Too Hot"),
    ]

    var body: some View {
        VStack(spacing: 16) {
            Divider()
                .overlay(AppTheme.line)

            Text("How did this outfit feel?")
                .font(.subheadline)
                .foregroundStyle(AppTheme.inkMuted)

            HStack(spacing: 10) {
                ForEach(options) { opt in
                    let selected = lastFeedback == opt.id
                    Button {
                        onFeedback(opt.id)
                    } label: {
                        HStack(spacing: 6) {
                            Text(opt.emoji)
                            Text(opt.label)
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(selected ? AppTheme.ink : AppTheme.surface)
                        .foregroundStyle(selected ? Color.white : AppTheme.inkSoft)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(AppTheme.line, lineWidth: selected ? 0 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            if lastFeedback != nil {
                Text("Saved locally — future fits will adapt slightly.")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.inkFaint)
            }
        }
        .padding(.top, 8)
    }
}
