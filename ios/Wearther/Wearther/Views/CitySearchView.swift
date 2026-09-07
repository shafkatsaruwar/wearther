import SwiftUI

struct CitySearchView: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) {
                viewModel.isCityPickerOpen.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Text(viewModel.location.name)
                    .font(AppFont.display(26))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Image(systemName: viewModel.isCityPickerOpen ? "chevron.up" : "chevron.down")
                    .font(AppFont.captionSemibold)
                    .foregroundStyle(AppTheme.inkMuted)
                    .padding(.top, 4)
            }
            .frame(minHeight: 40, alignment: .center)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Selected city \(viewModel.location.name). Change city")
        .sheet(isPresented: Binding(
            get: { viewModel.isCityPickerOpen },
            set: { viewModel.isCityPickerOpen = $0 }
        )) {
            cityPickerSheet
        }
    }

    private var cityPickerSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TextField("Search city…", text: Binding(
                    get: { viewModel.searchQuery },
                    set: { viewModel.updateSearchQuery($0) }
                ))
                .textFieldStyle(.plain)
                .font(AppFont.body)
                .padding(14)
                .background(AppTheme.surfaceHover)

                Divider()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        locateRow
                        savedSection
                        searchSection
                    }
                }
            }
            .background(AppTheme.cream.ignoresSafeArea())
            .navigationTitle("Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        viewModel.isCityPickerOpen = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private var locateRow: some View {
        Button {
            viewModel.locateMe()
        } label: {
            HStack(spacing: 10) {
                if viewModel.isLocating {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "location.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Locate Me")
                        .font(AppFont.subheadlineMedium)
                        .foregroundStyle(AppTheme.ink)
                    Text("Use your current location")
                        .font(AppFont.caption)
                        .foregroundStyle(AppTheme.inkMuted)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isLocating)
        .accessibilityLabel("Locate Me")

        Divider()
    }

    @ViewBuilder
    private var savedSection: some View {
        let queryEmpty = viewModel.searchQuery.trimmingCharacters(in: .whitespaces).count < 2
        if queryEmpty {
            if !viewModel.savedCities.isEmpty {
                Text("SAVED CITIES")
                    .font(AppFont.labelCaps)
                    .tracking(1.4)
                    .foregroundStyle(AppTheme.inkMuted)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 4)

                ForEach(viewModel.savedCities) { loc in
                    cityRow(loc, showBookmark: true)
                }
            }

            Text("SUGGESTED")
                .font(AppFont.labelCaps)
                .tracking(1.4)
                .foregroundStyle(AppTheme.inkMuted)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 4)

            ForEach(MockWeatherProvider.suggestedCities.filter { suggested in
                !viewModel.savedCities.contains(where: { $0.id == suggested.id })
            }) { loc in
                cityRow(loc, showBookmark: true)
            }
        }
    }

    @ViewBuilder
    private var searchSection: some View {
        let trimmed = viewModel.searchQuery.trimmingCharacters(in: .whitespaces)

        if trimmed.count >= 2 {
            Text("RESULTS")
                .font(AppFont.labelCaps)
                .tracking(1.4)
                .foregroundStyle(AppTheme.inkMuted)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 4)

            if viewModel.isSearching {
                Text("Searching…")
                    .font(AppFont.subheadline)
                    .foregroundStyle(AppTheme.inkMuted)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            } else if viewModel.searchResults.isEmpty {
                Text("No cities found")
                    .font(AppFont.subheadline)
                    .foregroundStyle(AppTheme.inkMuted)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            } else {
                ForEach(viewModel.searchResults) { loc in
                    cityRow(loc, showBookmark: true)
                }
            }
        }
    }

    private func cityRow(_ loc: LocationResult, showBookmark: Bool) -> some View {
        let selected = viewModel.location.id == loc.id
        let saved = viewModel.isSaved(loc)

        return HStack(spacing: 0) {
            Button {
                viewModel.selectLocation(loc)
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
                    Spacer(minLength: 8)
                    if selected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppTheme.accent)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 16)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showBookmark {
                Button {
                    viewModel.toggleSavedCity(loc)
                } label: {
                    Image(systemName: saved ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(saved ? AppTheme.accent : AppTheme.inkMuted)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(saved ? "Remove \(loc.name) from saved cities" : "Save \(loc.name)")
                .padding(.trailing, 6)
            }
        }
    }
}
