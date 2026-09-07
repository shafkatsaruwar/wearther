import SwiftUI

struct TripPackScreen: View {
    @StateObject private var viewModel: TripPackViewModel

    init(seedComfort: ComfortPreference = ComfortStore.loadComfortPreference()) {
        _viewModel = StateObject(wrappedValue: TripPackViewModel(seedComfort: seedComfort))
    }

    var body: some View {
        ZStack {
            AtmosphereBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    formCard
                    if viewModel.isLoading {
                        loadingCard
                    } else if let plan = viewModel.plan {
                        resultCard(plan)
                    } else {
                        emptyCard
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Trip Pack")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.light)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Trip Pack")
                .font(AppFont.display(34))
                .foregroundStyle(AppTheme.ink)
            Text("Pack for the weather before you go.")
                .font(AppFont.body)
                .foregroundStyle(AppTheme.inkSoft)
        }
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            destinationField
            daysStepper
            stylePicker
            alwaysPackToggles

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(AppFont.caption)
                    .foregroundStyle(AppTheme.coral)
            }

            Button {
                Task { await viewModel.buildPlan() }
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView().tint(.white)
                    }
                    Text(viewModel.isLoading ? "Building list…" : "Build packing list")
                        .font(AppFont.subheadlineMedium)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 48)
                .background(Capsule().fill(AppTheme.accent))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.destination == nil || viewModel.isLoading)
            .opacity(viewModel.destination == nil ? 0.55 : 1)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(radius: 28)
    }

    private var destinationField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Destination")
                .font(AppFont.subheadlineMedium)
                .foregroundStyle(AppTheme.ink)

            if let dest = viewModel.destination {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(dest.name)
                            .font(AppFont.subheadlineMedium)
                            .foregroundStyle(AppTheme.ink)
                        Text([dest.region, dest.country].compactMap { $0 }.joined(separator: ", "))
                            .font(AppFont.caption)
                            .foregroundStyle(AppTheme.inkMuted)
                            .lineLimit(1)
                    }
                    Spacer()
                    Button("Change") { viewModel.clearDestination() }
                        .font(AppFont.caption)
                        .foregroundStyle(AppTheme.accent)
                        .frame(minHeight: 44)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppTheme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(AppTheme.line, lineWidth: 1)
                        )
                )
            } else {
                TextField("Search destination…", text: Binding(
                    get: { viewModel.searchQuery },
                    set: { viewModel.updateSearchQuery($0) }
                ))
                .textFieldStyle(.plain)
                .font(AppFont.body)
                .padding(14)
                .frame(minHeight: 48)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppTheme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(AppTheme.line, lineWidth: 1)
                        )
                )

                if viewModel.isSearching {
                    Text("Searching…")
                        .font(AppFont.caption)
                        .foregroundStyle(AppTheme.inkMuted)
                } else if !viewModel.searchResults.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(viewModel.searchResults.prefix(5)) { loc in
                            Button {
                                viewModel.selectDestination(loc)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(loc.name)
                                            .font(AppFont.subheadlineMedium)
                                            .foregroundStyle(AppTheme.ink)
                                        Text([loc.region, loc.country].compactMap { $0 }.joined(separator: ", "))
                                            .font(AppFont.caption)
                                            .foregroundStyle(AppTheme.inkMuted)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .frame(minHeight: 44)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            if loc.id != viewModel.searchResults.prefix(5).last?.id {
                                Divider().opacity(0.35)
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppTheme.surfaceHover)
                    )
                }
            }
        }
    }

    private var daysStepper: some View {
        HStack {
            Text("Trip length")
                .font(AppFont.subheadline)
                .foregroundStyle(AppTheme.inkSoft)
            Spacer()
            HStack(spacing: 14) {
                stepButton(systemName: "minus") {
                    viewModel.days = max(1, viewModel.days - 1)
                }
                Text("\(viewModel.days) day\(viewModel.days == 1 ? "" : "s")")
                    .font(AppFont.subheadlineMedium)
                    .foregroundStyle(AppTheme.ink)
                    .frame(minWidth: 64)
                stepButton(systemName: "plus") {
                    viewModel.days = min(7, viewModel.days + 1)
                }
            }
        }
    }

    private func stepButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
                .frame(width: 44, height: 44)
                .background(Circle().fill(AppTheme.surface))
                .overlay(Circle().stroke(AppTheme.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var stylePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Style")
                .font(AppFont.subheadlineMedium)
                .foregroundStyle(AppTheme.ink)
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 120), spacing: 8, alignment: .leading)],
                alignment: .leading,
                spacing: 8
            ) {
                ForEach(StyleMode.allCases, id: \.self) { mode in
                    let selected = viewModel.style == mode
                    Button {
                        viewModel.style = mode
                    } label: {
                        Text(mode.label)
                            .font(AppFont.subheadline)
                            .foregroundStyle(selected ? Color.white : AppTheme.inkSoft)
                            .padding(.horizontal, 14)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 44)
                            .background(selected ? AppTheme.ink : AppTheme.surface)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var alwaysPackToggles: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Always pack")
                .font(AppFont.subheadlineMedium)
                .foregroundStyle(AppTheme.ink)
            packToggle("Rain shell", isOn: viewModel.alwaysPack.rainJacket) {
                viewModel.alwaysPack.rainJacket = $0
            }
            packToggle("Light layer", isOn: viewModel.alwaysPack.lightLayer) {
                viewModel.alwaysPack.lightLayer = $0
            }
            packToggle("Scarf", isOn: viewModel.alwaysPack.scarf) {
                viewModel.alwaysPack.scarf = $0
            }
        }
    }

    private func packToggle(_ label: String, isOn: Bool, onChange: @escaping (Bool) -> Void) -> some View {
        HStack {
            Text(label)
                .font(AppFont.subheadline)
                .foregroundStyle(AppTheme.inkSoft)
            Spacer()
            Toggle("", isOn: Binding(get: { isOn }, set: onChange))
                .labelsHidden()
                .tint(AppTheme.accent)
                .frame(minHeight: 44)
        }
    }

    private var emptyCard: some View {
        VStack(spacing: 14) {
            Image("BrandMark")
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            Text("Pick a destination to build your list.")
                .font(AppFont.subheadline)
                .foregroundStyle(AppTheme.inkMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .cardSurface(radius: 24)
    }

    private var loadingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.surface)
                .frame(height: 22)
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.surface)
                .frame(height: 88)
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.surface)
                .frame(height: 140)
        }
        .padding(18)
        .cardSurface(radius: 28)
        .redacted(reason: .placeholder)
    }

    private func resultCard(_ plan: TripPackPlan) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(plan.summary)
                .font(AppFont.subheadlineMedium)
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            if !plan.daysCovered.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(plan.daysCovered) { day in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(dayLabel(day.date))
                                    .font(AppFont.caption2)
                                    .foregroundStyle(AppTheme.inkMuted)
                                Text("\(TemperatureDisplay.value(day.high, units: viewModel.units))°/\(TemperatureDisplay.value(day.low, units: viewModel.units))°")
                                    .font(AppFont.caption)
                                    .foregroundStyle(AppTheme.ink)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(AppTheme.sky.opacity(0.9))
                            )
                        }
                    }
                }
            }

            if !plan.warnings.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(plan.warnings, id: \.self) { warning in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.circle")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(AppTheme.coral)
                                .padding(.top, 1)
                            Text(warning)
                                .font(AppFont.caption)
                                .foregroundStyle(AppTheme.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            ForEach(plan.groups) { group in
                VStack(alignment: .leading, spacing: 8) {
                    Text(group.category.rawValue.uppercased())
                        .font(AppFont.labelCaps)
                        .tracking(1.4)
                        .foregroundStyle(AppTheme.inkMuted)
                    ForEach(group.items, id: \.self) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(AppTheme.accent)
                                .padding(.top, 2)
                            Text(item)
                                .font(AppFont.subheadline)
                                .foregroundStyle(AppTheme.ink)
                        }
                    }
                }
            }

            ForEach(plan.notes, id: \.self) { note in
                Text(note)
                    .font(AppFont.caption)
                    .foregroundStyle(AppTheme.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                Task { await viewModel.buildPlan() }
            } label: {
                Text("Rebuild list")
                    .font(AppFont.subheadlineMedium)
                    .foregroundStyle(AppTheme.accent)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .background(
                        Capsule()
                            .stroke(AppTheme.accent.opacity(0.35), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(radius: 28)
    }

    private func dayLabel(_ iso: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: iso) {
            return date.formatted(.dateTime.weekday(.abbreviated))
        }
        let dayOnly = DateFormatter()
        dayOnly.locale = Locale(identifier: "en_US_POSIX")
        dayOnly.dateFormat = "yyyy-MM-dd"
        if let date = dayOnly.date(from: String(iso.prefix(10))) {
            return date.formatted(.dateTime.weekday(.abbreviated))
        }
        return iso
    }
}

#Preview {
    NavigationStack {
        TripPackScreen()
    }
}
