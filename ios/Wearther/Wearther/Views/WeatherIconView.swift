import SwiftUI

struct WeatherIconView: View {
    let code: String

    var body: some View {
        Image(systemName: symbolName)
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(AppTheme.accent)
    }

    private var symbolName: String {
        switch code {
        case "clear": return "sun.max.fill"
        case "partly-cloudy": return "cloud.sun.fill"
        case "cloudy": return "cloud.fill"
        case "rain": return "cloud.rain.fill"
        case "snow": return "cloud.snow.fill"
        case "storm": return "cloud.bolt.rain.fill"
        case "fog": return "cloud.fog.fill"
        case "windy": return "wind"
        default: return "cloud.sun.fill"
        }
    }
}
