import SwiftUI

struct SweataWeathaView: View {
    let moment: SweataWeathaMoment

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text("🧣")
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(moment.headline)
                        .font(AppTheme.titleSweata)
                        .foregroundStyle(AppTheme.ink)

                    Text(moment.subtitle)
                        .font(AppTheme.captionMedium)
                        .foregroundStyle(AppTheme.accent)
                }
            }

            Text(moment.line)
                .font(AppTheme.body)
                .foregroundStyle(AppTheme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.94, green: 0.90, blue: 0.87),
                    Color(red: 0.90, green: 0.91, blue: 0.88),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppTheme.accent.opacity(0.25), lineWidth: 1)
        )
    }
}

#Preview {
    SweataWeathaView(
        moment: SweataWeathaMoment(
            headline: "Sweata Weatha",
            subtitle: "Out theah in Boston — wicked nice sweata weatha",
            line: "Pahfect sweata weatha. A sweater and jeans oughta do ya just fine.",
            isTomorrow: false
        )
    )
    .padding()
}
