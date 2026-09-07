import SwiftUI

struct TripPackEntryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Planning a trip?")
                .font(AppFont.subheadlineMedium)
                .foregroundStyle(AppTheme.ink)

            Text("Get a weather-aware packing list.")
                .font(AppFont.caption)
                .foregroundStyle(AppTheme.inkMuted)
                .fixedSize(horizontal: false, vertical: true)

            NavigationLink {
                TripPackScreen()
            } label: {
                Text("Open Trip Pack")
                    .font(AppFont.subheadlineMedium)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .background(Capsule().fill(AppTheme.accent))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(radius: 24)
    }
}
