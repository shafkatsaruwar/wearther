import SwiftUI

struct CustomizeView: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("YOUR PREFERENCES")
                    .font(AppFont.labelCaps)
                    .tracking(2.2)
                    .foregroundStyle(AppTheme.accent)
                Spacer()
                Button("Done") {
                    viewModel.isCustomizeOpen = false
                }
                .font(AppFont.subheadline)
                .foregroundStyle(AppTheme.inkMuted)
            }

            prefCard(title: "I usually feel") {
                FlowChips(
                    options: FeelBaseline.allCases.map { ($0, $0.label) },
                    selected: viewModel.comfort.feelBaseline
                ) { value in
                    viewModel.updateFeelBaseline(value)
                }
            }

            prefCard(title: "Style") {
                FlowChips(
                    options: StyleMode.allCases.map { ($0, $0.label) },
                    selected: viewModel.comfort.style
                ) { value in
                    viewModel.updateStyle(value)
                }
            }

            prefCard(title: "Always pack") {
                VStack(spacing: 14) {
                    packToggle("Rain jacket", isOn: viewModel.comfort.alwaysPack.rainJacket) {
                        viewModel.updateAlwaysPack(rainJacket: $0)
                    }
                    packToggle("Light layer for later", isOn: viewModel.comfort.alwaysPack.lightLayer) {
                        viewModel.updateAlwaysPack(lightLayer: $0)
                    }
                    packToggle("Scarf", isOn: viewModel.comfort.alwaysPack.scarf) {
                        viewModel.updateAlwaysPack(scarf: $0)
                    }
                }
            }

            prefCard(title: "Units") {
                HStack(spacing: 0) {
                    unitButton(.fahrenheit, label: "°F")
                    unitButton(.celsius, label: "°C")
                }
                .padding(4)
                .background(AppTheme.fitIconBg)
                .clipShape(Capsule())
            }

            prefCard(title: "Morning nudge") {
                VStack(alignment: .leading, spacing: 14) {
                    packToggle("Daily notification", isOn: viewModel.notifications.enabled) { enabled in
                        viewModel.updateNotifications(enabled: enabled)
                    }

                    Text("Time")
                        .font(AppFont.caption)
                        .foregroundStyle(AppTheme.inkMuted)

                    HStack(spacing: 8) {
                        ForEach(MorningNotifyHour.allCases) { hour in
                            let selected = viewModel.notifications.hour == hour
                            Button {
                                viewModel.updateNotifications(hour: hour)
                            } label: {
                                Text(hour.label)
                                    .font(AppFont.subheadline)
                                    .foregroundStyle(selected ? Color.white : AppTheme.inkSoft)
                                    .frame(maxWidth: .infinity)
                                    .frame(minHeight: 44)
                                    .background(selected ? AppTheme.ink : AppTheme.surface)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .disabled(!viewModel.notifications.enabled)
                            .opacity(viewModel.notifications.enabled ? 1 : 0.5)
                        }
                    }

                    packToggle("Weekdays only", isOn: viewModel.notifications.weekdaysOnly) {
                        viewModel.updateNotifications(weekdaysOnly: $0)
                    }
                    .disabled(!viewModel.notifications.enabled)
                    .opacity(viewModel.notifications.enabled ? 1 : 0.5)

                    Text("Example: “Boston is breezy. Long sleeve, no jacket. Pack a light layer after 6 PM.”")
                        .font(AppFont.caption)
                        .foregroundStyle(AppTheme.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.top, 8)
    }

    private func prefCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(AppFont.subheadlineMedium)
                .foregroundStyle(AppTheme.ink)
            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppTheme.fitSurface)
        )
    }

    private func packToggle(_ label: String, isOn: Bool, onChange: @escaping (Bool) -> Void) -> some View {
        HStack {
            Text(label)
                .font(AppFont.subheadline)
                .foregroundStyle(AppTheme.inkSoft)
            Spacer()
            Toggle("", isOn: Binding(
                get: { isOn },
                set: onChange
            ))
            .labelsHidden()
            .tint(AppTheme.accent)
        }
    }

    private func unitButton(_ unit: TempUnits, label: String) -> some View {
        let selected = viewModel.comfort.units == unit
        return Button {
            viewModel.updateUnits(unit)
        } label: {
            Text(label)
                .font(AppFont.subheadline)
                .foregroundStyle(selected ? Color.white : AppTheme.inkMuted)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selected ? AppTheme.ink : Color.clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct FlowChips<T: Hashable>: View {
    let options: [(T, String)]
    let selected: T
    let onSelect: (T) -> Void

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 120), spacing: 8, alignment: .leading)],
            alignment: .leading,
            spacing: 8
        ) {
            ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                let isSelected = option.0 == selected
                Button {
                    onSelect(option.0)
                } label: {
                    Text(option.1)
                        .font(AppFont.subheadline)
                        .foregroundStyle(isSelected ? Color.white : AppTheme.inkSoft)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(isSelected ? AppTheme.ink : AppTheme.surface)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
