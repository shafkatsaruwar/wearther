import SwiftUI

struct CitySearchView: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    viewModel.isCityPickerOpen.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Text(viewModel.location.name)
                        .font(AppFont.cityName)
                        .foregroundStyle(AppTheme.ink)
                    Image(systemName: "chevron.down")
                        .font(AppFont.captionSemibold)
                        .foregroundStyle(AppTheme.inkMuted)
                        .padding(.top, 6)
                }
            }
            .buttonStyle(.plain)

            if viewModel.isCityPickerOpen {
                VStack(spacing: 0) {
                    TextField("Search city…", text: Binding(
                        get: { viewModel.searchQuery },
                        set: { viewModel.updateSearchQuery($0) }
                    ))
                    .textFieldStyle(.plain)
                    .font(AppFont.body)
                    .padding(12)
                    .foregroundStyle(AppTheme.ink)

                    Divider()

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            if viewModel.isSearching && viewModel.searchQuery.trimmingCharacters(in: .whitespaces).count >= 2 {
                                Text("Searching…")
                                    .font(AppFont.subheadline)
                                    .foregroundStyle(AppTheme.inkMuted)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                            } else if viewModel.searchQuery.trimmingCharacters(in: .whitespaces).count >= 2 && viewModel.searchResults.isEmpty && !viewModel.isSearching {
                                Text("No cities found")
                                    .font(AppFont.subheadline)
                                    .foregroundStyle(AppTheme.inkMuted)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                            } else if viewModel.searchQuery.trimmingCharacters(in: .whitespaces).count < 2 {
                                Text("Type at least 2 letters")
                                    .font(AppFont.subheadline)
                                    .foregroundStyle(AppTheme.inkMuted)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                            }

                            ForEach(viewModel.searchResults) { loc in
                                Button {
                                    viewModel.selectLocation(loc)
                                } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(loc.name)
                                            .font(AppFont.subheadlineMedium)
                                            .foregroundStyle(AppTheme.ink)
                                        Text([loc.region, loc.country].compactMap { $0 }.joined(separator: ", "))
                                            .font(AppFont.caption)
                                            .foregroundStyle(AppTheme.inkMuted)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxHeight: 260)
                }
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppTheme.line, lineWidth: 1)
                )
                .padding(.top, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
