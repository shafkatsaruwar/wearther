import WidgetKit
import SwiftUI

struct WeartherWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct WeartherWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeartherWidgetEntry {
        WeartherWidgetEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (WeartherWidgetEntry) -> Void) {
        let snap = WidgetSnapshotStore.load() ?? .placeholder
        completion(WeartherWidgetEntry(date: Date(), snapshot: snap))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeartherWidgetEntry>) -> Void) {
        var snap = WidgetSnapshotStore.load() ?? .placeholder
        if Date().timeIntervalSince(snap.updatedAt) > 3 * 60 * 60 {
            snap.isStale = true
        }
        let entry = WeartherWidgetEntry(date: Date(), snapshot: snap)
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())
            ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}
