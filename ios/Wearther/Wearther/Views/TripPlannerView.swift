import SwiftUI

struct TripPlannerView: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("TRIP PACK")
                .font(AppFont.labelCaps)
                .tracking(2.2)
                .foregroundStyle(AppTheme.inkMuted)

            Text("Going somewhere?")
                .font(AppFont.subheadlineMedium)
                .foregroundStyle(AppTheme.ink)

            Text("Pick a destination and how many days — Wearther maps the forecast into what to pack.")
                .font(AppFont.caption)
                .foregroundStyle(AppTheme.inkMuted)
                .fixedSize(horizontal: false, vertical: true)

            destinationField
            daysStepper

            if let error = viewModel.tripError {
                Text(error)
                    .font(AppFont.caption)
                    .foregroundStyle(AppTheme.inkMuted)
            }

            Button {
                Task { await viewModel.buildTripPlan() }
            } label: {
                HStack {
                    if viewModel.isTripLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(viewModel.isTripLoading ? "Checking forecast…" : "What should I pack?")
                        .font(AppFont.subheadlineMedium)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 48)
                .background(Capsule().fill(AppTheme.accent))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.tripDestination == nil || viewModel.isTripLoading)

            if let plan = viewModel.tripPlan {
                planCard(plan)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(radius: 24)
    }

    private var destinationField: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let dest = viewModel.tripDestination {
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
                    Button("Change") {
                        viewModel.clearTripDestination()
                    }
                    .font(AppFont.caption)
                    .foregroundStyle(AppTheme.accent)
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
                    get: { viewModel.tripSearchQuery },
                    set: { viewModel.updateTripSearchQuery($0) }
                ))
                .textFieldStyle(.plain)
                .font(AppFont.body)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppTheme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(AppTheme.line, lineWidth: 1)
                        )
                )

                if viewModel.isTripSearching {
                    Text("Searching…")
                        .font(AppFont.caption)
                        .foregroundStyle(AppTheme.inkMuted)
                } else if !viewModel.tripSearchResults.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(viewModel.tripSearchResults.prefix(5)) { loc in
                            Button {
                                viewModel.selectTripDestination(loc)
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
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            if loc.id != viewModel.tripSearchResults.prefix(5).last?.id {
                                Divider().opacity(0.4)
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
            Text("How many days?")
                .font(AppFont.subheadline)
                .foregroundStyle(AppTheme.inkSoft)

            Spacer()

            HStack(spacing: 14) {
                Button {
                    viewModel.tripDays = max(1, viewModel.tripDays - 1)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(AppTheme.surface))
                        .overlay(Circle().stroke(AppTheme.line, lineWidth: 1))
                }
                .buttonStyle(.plain)

                Text("\(viewModel.tripDays)")
                    .font(AppFont.subheadlineMedium)
                    .foregroundStyle(AppTheme.ink)
                    .frame(minWidth: 24)

                Button {
                    viewModel.tripDays = min(7, viewModel.tripDays + 1)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(AppTheme.surface))
                        .overlay(Circle().stroke(AppTheme.line, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func planCard(_ plan: TripPackPlan) -> some View {
        VStack(alignment: .leading, spacing: 14) {
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
                                Text("\(TemperatureDisplay.value(day.high, units: viewModel.comfort.units))°/\(TemperatureDisplay.value(day.low, units: viewModel.comfort.units))°")
                                    .font(AppFont.caption)
                                    .foregroundStyle(AppTheme.ink)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(AppTheme.surface)
                            )
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Pack")
                    .font(AppFont.labelCaps)
                    .tracking(1.4)
                    .foregroundStyle(AppTheme.inkMuted)

                ForEach(plan.packItems, id: \.self) { item in
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

            ForEach(plan.notes, id: \.self) { note in
                Text(note)
                    .font(AppFont.caption)
                    .foregroundStyle(AppTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.fitSurface)
        )
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
