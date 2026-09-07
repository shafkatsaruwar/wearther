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
        let staleHours = RemoteConfigStore.current.timing.widgetStaleHours
        if Date().timeIntervalSince(snap.updatedAt) > Double(staleHours) * 60 * 60 {
            snap.isStale = true
        }
        let entry = WeartherWidgetEntry(date: Date(), snapshot: snap)
        let minutes = max(15, RemoteConfigStore.current.timing.widgetRefreshMinutes)
        let next = Calendar.current.date(byAdding: .minute, value: minutes, to: Date())
            ?? Date().addingTimeInterval(Double(minutes) * 60)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}
