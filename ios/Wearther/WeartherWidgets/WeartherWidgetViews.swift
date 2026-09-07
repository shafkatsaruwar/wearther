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
        .padding(14)
        .widgetPanelBackground {
            WidgetPalette.deepTeal
        }
    }
}

struct MediumFitWidgetView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(snapshot.locationDateLabel)
                    .font(WidgetPalette.sans(10, weight: .semibold))
                    .tracking(0.3)
                    .foregroundStyle(WidgetPalette.cream.opacity(0.7))
                    .lineLimit(1)

                Text(snapshot.shortOutfitTitle)
                    .font(WidgetPalette.display(22))
                    .foregroundStyle(WidgetPalette.cream)
                    .minimumScaleFactor(0.65)
                    .lineLimit(2)

                Text(snapshot.confidenceLabel)
                    .font(WidgetPalette.sans(10, weight: .semibold))
                    .foregroundStyle(WidgetPalette.sun)
                    .lineLimit(1)

                Spacer(minLength: 0)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(snapshot.temperatureLabel)
                        .font(WidgetPalette.display(24, weight: .regular))
                        .foregroundStyle(WidgetPalette.cream)
                        .lineLimit(1)

                    Text(snapshot.windLabel)
                        .font(WidgetPalette.sans(11, weight: .medium))
                        .foregroundStyle(WidgetPalette.cream.opacity(0.8))
                        .lineLimit(1)
                }

                if snapshot.isStale {
                    Text(snapshot.updatedLabel)
                        .font(WidgetPalette.sans(9, weight: .medium))
                        .foregroundStyle(WidgetPalette.cream.opacity(0.5))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

            VStack(spacing: 6) {
                ForEach(Array(snapshot.itemSymbols.prefix(3).enumerated()), id: \.offset) { _, symbol in
                    ZStack {
                        Circle()
                            .fill(WidgetPalette.cream.opacity(0.14))
                        Image(systemName: symbol)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(WidgetPalette.cream)
                    }
                    .frame(width: 30, height: 30)
                }
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetPanelBackground {
            LinearGradient(
                colors: [
                    WidgetPalette.deepTeal,
                    Color(red: 0.055, green: 0.34, blue: 0.31),
                ],
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
        .padding(16)
        .widgetPanelBackground {
            WidgetPalette.cream
        }
    }
}

private extension View {
    /// System widget chrome fills edge-to-edge; content stays inside margins.
    /// Avoid clipping the content view — that was cutting off title/icons.
    func widgetPanelBackground<Background: View>(
        @ViewBuilder _ background: () -> Background
    ) -> some View {
        self.containerBackground(for: .widget) {
            background()
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
