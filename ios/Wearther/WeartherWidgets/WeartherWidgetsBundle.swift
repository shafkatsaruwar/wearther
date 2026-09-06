import WidgetKit
import SwiftUI

struct WeartherWidgets: Widget {
    let kind = "WeartherFitWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeartherWidgetProvider()) { entry in
            WeartherWidgetEntryView(entry: entry)
                .widgetURL(URL(string: "wearther://home"))
        }
        .configurationDisplayName("Today's Fit")
        .description("Outfit advice first, weather second.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryInline,
            .accessoryRectangular,
        ])
    }
}

struct WeartherWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: WeartherWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallFitWidgetView(snapshot: entry.snapshot)
        case .systemMedium:
            MediumFitWidgetView(snapshot: entry.snapshot)
        case .systemLarge:
            LargeFitWidgetView(snapshot: entry.snapshot)
        case .accessoryCircular:
            LockCircularFitView(snapshot: entry.snapshot)
        case .accessoryInline:
            LockInlineFitView(snapshot: entry.snapshot)
        case .accessoryRectangular:
            LockRectangularFitView(snapshot: entry.snapshot)
        default:
            MediumFitWidgetView(snapshot: entry.snapshot)
        }
    }
}

@main
struct WeartherWidgetsBundle: WidgetBundle {
    var body: some Widget {
        WeartherWidgets()
    }
}

#Preview("Small", as: .systemSmall) {
    WeartherWidgets()
} timeline: {
    WeartherWidgetEntry(date: .now, snapshot: .placeholder)
}

#Preview("Medium", as: .systemMedium) {
    WeartherWidgets()
} timeline: {
    WeartherWidgetEntry(date: .now, snapshot: .placeholder)
}

#Preview("Large", as: .systemLarge) {
    WeartherWidgets()
} timeline: {
    WeartherWidgetEntry(date: .now, snapshot: .placeholder)
}

#Preview("Lock Circular", as: .accessoryCircular) {
    WeartherWidgets()
} timeline: {
    WeartherWidgetEntry(date: .now, snapshot: .placeholder)
}

#Preview("Lock Inline", as: .accessoryInline) {
    WeartherWidgets()
} timeline: {
    WeartherWidgetEntry(date: .now, snapshot: .placeholder)
}

#Preview("Lock Rectangular", as: .accessoryRectangular) {
    WeartherWidgets()
} timeline: {
    WeartherWidgetEntry(date: .now, snapshot: .placeholder)
}
