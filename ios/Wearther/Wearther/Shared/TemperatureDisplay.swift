import Foundation

enum TemperatureDisplay {
    static func value(_ fahrenheit: Int, units: TempUnits) -> Int {
        if units == .celsius {
            return Int(round(Double(fahrenheit - 32) * 5.0 / 9.0))
        }
        return fahrenheit
    }

    static func wind(_ mph: Int, units: TempUnits) -> String {
        if units == .celsius {
            return "\(Int(round(Double(mph) * 1.609))) km/h"
        }
        return "\(mph) mph"
    }
}
