import SwiftUI

struct NotificationSettingsView: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "bell.badge.fill")
                    .font(.title3)
                    .foregroundStyle(AppTheme.accent)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Tomorrow alerts")
                        .font(AppTheme.subheadlineSemibold)
                        .foregroundStyle(AppTheme.ink)
                    Text("Get a heads-up around \(NotificationService.formattedNextDeliveryTime()) when rain, snow, or extreme temps are expected.")
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Toggle("", isOn: Binding(
                    get: { viewModel.notificationsEnabled },
                    set: { newValue in
                        Task { await viewModel.setNotificationsEnabled(newValue) }
                    }
                ))
                .labelsHidden()
                .tint(AppTheme.accent)
            }

            if viewModel.notificationPermissionDenied {
                Text("Notifications are off in Settings. Enable them to get tomorrow's weather alerts.")
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.inkSoft)
            }

            if viewModel.notificationsEnabled, let preview = viewModel.notificationPreview {
                VStack(alignment: .leading, spacing: 6) {
                    Text("NEXT ALERT PREVIEW")
                        .font(AppTheme.micro)
                        .tracking(1.6)
                        .foregroundStyle(AppTheme.inkFaint)

                    Text(preview.title)
                        .font(AppTheme.subheadlineSemibold)
                        .foregroundStyle(AppTheme.ink)

                    Text(preview.body)
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppTheme.line, lineWidth: 1)
                )
            } else if viewModel.notificationsEnabled {
                Text("No alerts needed for tomorrow — weather looks manageable.")
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.inkFaint)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.fitSurface.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppTheme.line, lineWidth: 1)
        )
    }
}
