import SwiftUI

struct ComfortFeedbackView: View {
    let lastFeedback: ComfortFeedback?
    let onFeedback: (ComfortFeedback) -> Void

    private struct Option: Identifiable {
        let id: ComfortFeedback
        let label: String
        let primary: Bool
    }

    private let options: [Option] = [
        .init(id: .tooCold, label: "Too Cold", primary: false),
        .init(id: .perfect, label: "Perfect", primary: true),
        .init(id: .tooHot, label: "Too Hot", primary: false),
    ]

    var body: some View {
        VStack(spacing: 16) {
            Text("HOW WOULD THIS FEEL?")
                .font(AppFont.labelCaps)
                .tracking(1.8)
                .foregroundStyle(AppTheme.inkMuted)

            HStack(spacing: 8) {
                ForEach(options) { opt in
                    let selected = lastFeedback == opt.id
                    Button {
                        onFeedback(opt.id)
                    } label: {
                        Text(opt.label)
                            .font(AppFont.subheadlineMedium)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 44)
                            .foregroundStyle(foreground(selected: selected, primary: opt.primary))
                            .background(background(selected: selected, primary: opt.primary))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(opt.label)
                }
            }

            if lastFeedback != nil {
                Text("Saved locally — future fits will adapt slightly.")
                    .font(AppFont.caption2)
                    .foregroundStyle(AppTheme.inkFaint)
            }
        }
        .padding(.top, 8)
    }

    private func foreground(selected: Bool, primary: Bool) -> Color {
        if selected { return .white }
        return primary ? AppTheme.accent : AppTheme.inkSoft
    }

    @ViewBuilder
    private func background(selected: Bool, primary: Bool) -> some View {
        if selected {
            Capsule().fill(primary ? AppTheme.accent : AppTheme.ink)
        } else if primary {
            Capsule()
                .fill(AppTheme.accent.opacity(0.12))
                .overlay(Capsule().stroke(AppTheme.accent.opacity(0.28), lineWidth: 1))
        } else {
            Capsule()
                .fill(AppTheme.surface)
                .overlay(Capsule().stroke(AppTheme.line, lineWidth: 1))
        }
    }
}
