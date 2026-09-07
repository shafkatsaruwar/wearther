import SwiftUI
import WidgetKit

struct SmallFitWidgetView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TODAY'S FIT")
                .font(WidgetPalette.sans(10, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(WidgetPalette.cream.opacity(0.72))

            Text(snapshot.shortOutfitTitle)
                .font(WidgetPalette.display(22))
                .foregroundStyle(WidgetPalette.cream)
                .minimumScaleFactor(0.75)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            Text(snapshot.weatherContext)
                .font(WidgetPalette.sans(12, weight: .medium))
                .foregroundStyle(WidgetPalette.cream.opacity(0.85))
                .lineLimit(1)

            if let hint = snapshot.packHint {
                Text(hint)
                    .font(WidgetPalette.sans(11, weight: .semibold))
                    .foregroundStyle(WidgetPalette.sun)
                    .lineLimit(1)
            }

            if snapshot.isStale {
                Text(snapshot.updatedLabel)
                    .font(WidgetPalette.sans(9, weight: .medium))
                    .foregroundStyle(WidgetPalette.cream.opacity(0.55))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            WidgetPalette.deepTeal
        }
    }
}

struct MediumFitWidgetView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text(snapshot.locationDateLabel)
                    .font(WidgetPalette.sans(11, weight: .semibold))
                    .tracking(0.4)
                    .foregroundStyle(WidgetPalette.cream.opacity(0.7))
                    .lineLimit(1)

                Text(snapshot.outfitTitle)
                    .font(WidgetPalette.display(26))
                    .foregroundStyle(WidgetPalette.cream)
                    .minimumScaleFactor(0.7)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                Text(snapshot.confidenceLabel)
                    .font(WidgetPalette.sans(11, weight: .semibold))
                    .foregroundStyle(WidgetPalette.sun)
                    .lineLimit(1)

                Spacer(minLength: 4)

                HStack(spacing: 10) {
                    Text(snapshot.temperatureLabel)
                        .font(WidgetPalette.display(28, weight: .regular))
                        .foregroundStyle(WidgetPalette.cream)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(snapshot.windLabel)
                            .font(WidgetPalette.sans(12, weight: .medium))
                            .foregroundStyle(WidgetPalette.cream.opacity(0.8))
                        Text(snapshot.condition)
                            .font(WidgetPalette.sans(12, weight: .medium))
                            .foregroundStyle(WidgetPalette.cream.opacity(0.7))
                            .lineLimit(1)
                    }
                }

                if snapshot.isStale {
                    Text(snapshot.updatedLabel)
                        .font(WidgetPalette.sans(9, weight: .medium))
                        .foregroundStyle(WidgetPalette.cream.opacity(0.5))
                }
            }

            Spacer(minLength: 0)

            VStack(spacing: 10) {
                Image("BrandMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Spacer(minLength: 0)

                ForEach(Array(snapshot.itemSymbols.prefix(3).enumerated()), id: \.offset) { _, symbol in
                    ZStack {
                        Circle()
                            .fill(WidgetPalette.cream.opacity(0.14))
                        Image(systemName: symbol)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(WidgetPalette.cream)
                    }
                    .frame(width: 36, height: 36)
                }
            }
            .frame(width: 44)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [WidgetPalette.deepTeal, WidgetPalette.sage],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct LargeFitWidgetView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image("BrandMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                Text("Wearther")
                    .font(WidgetPalette.sans(14, weight: .semibold))
                    .foregroundStyle(WidgetPalette.ink)

                Spacer()

                Text(snapshot.confidenceLabel)
                    .font(WidgetPalette.sans(11, weight: .semibold))
                    .foregroundStyle(WidgetPalette.deepTeal)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(WidgetPalette.mint))
            }

            Text(snapshot.outfitTitle)
                .font(WidgetPalette.display(32))
                .foregroundStyle(WidgetPalette.ink)
                .minimumScaleFactor(0.75)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text(snapshot.explanation)
                .font(WidgetPalette.sans(14, weight: .medium))
                .foregroundStyle(WidgetPalette.ink.opacity(0.72))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            if !snapshot.laterHours.isEmpty {
                Text("LATER TODAY")
                    .font(WidgetPalette.sans(10, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(WidgetPalette.ink.opacity(0.45))
                    .padding(.top, 2)

                HStack(spacing: 8) {
                    ForEach(snapshot.laterHours.prefix(3)) { slot in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(slot.timeLabel)
                                .font(WidgetPalette.sans(11, weight: .medium))
                                .foregroundStyle(WidgetPalette.ink.opacity(0.5))
                            Text("\(slot.temperature)°")
                                .font(WidgetPalette.display(20, weight: .regular))
                                .foregroundStyle(WidgetPalette.ink)
                            Text(slot.tip)
                                .font(WidgetPalette.sans(11, weight: .medium))
                                .foregroundStyle(WidgetPalette.deepTeal)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(WidgetPalette.paleSky.opacity(0.85))
                        )
                    }
                }
            }

            if snapshot.isStale {
                Text(snapshot.updatedLabel)
                    .font(WidgetPalette.sans(10, weight: .medium))
                    .foregroundStyle(WidgetPalette.ink.opacity(0.4))
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            WidgetPalette.cream
        }
    }
}

struct LockCircularFitView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(systemName: snapshot.itemSymbols.first ?? "tshirt")
                .font(.system(size: 20, weight: .semibold))
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

struct LockInlineFitView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        Text(snapshot.lockInline)
            .containerBackground(for: .widget) {
                Color.clear
            }
    }
}

struct LockRectangularFitView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(snapshot.lockRectangularPrimary)
                .font(.headline)
                .lineLimit(1)
            Text(snapshot.lockRectangularSecondary)
                .font(.caption)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}
