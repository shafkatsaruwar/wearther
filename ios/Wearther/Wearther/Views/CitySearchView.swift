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
                HStack(spacing: 8) {
                    Text(viewModel.location.name)
                        .font(.system(size: 34, weight: .semibold, design: .serif))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.inkMuted)

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if viewModel.isCityPickerOpen {
                VStack(spacing: 0) {
                    TextField("Search city…", text: Binding(
                        get: { viewModel.searchQuery },
                        set: { viewModel.updateSearchQuery($0) }
                    ))
                    .textFieldStyle(.plain)
                    .padding(12)
                    .foregroundStyle(AppTheme.ink)

                    Divider()

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            if viewModel.isSearching && viewModel.searchQuery.trimmingCharacters(in: .whitespaces).count >= 2 {
                                Text("Searching…")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.inkMuted)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                            } else if viewModel.searchQuery.trimmingCharacters(in: .whitespaces).count >= 2 && viewModel.searchResults.isEmpty && !viewModel.isSearching {
                                Text("No cities found")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.inkMuted)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                            } else if viewModel.searchQuery.trimmingCharacters(in: .whitespaces).count < 2 {
                                Text("Type at least 2 letters")
                                    .font(.subheadline)
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
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(AppTheme.ink)
                                        Text([loc.region, loc.country].compactMap { $0 }.joined(separator: ", "))
                                            .font(.caption)
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
