import Foundation
import SwiftUI
import Combine

class WeightFormatter: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    
    static let shared = WeightFormatter()
    
    private init() {}
    
    // Get the user's preferred weight unit from system settings
    var preferredUnit: UnitMass {
        let locale = Locale.current
        let usesMetric = locale.usesMetricSystem
        
        if usesMetric {
            return .kilograms
        } else {
            return .pounds
        }
    }
    
    // Convert kg to the preferred unit
    func convertFromKilograms(_ kg: Double) -> Double {
        let measurement = Measurement(value: kg, unit: UnitMass.kilograms)
        return measurement.converted(to: preferredUnit).value
    }
    
    // Convert from preferred unit to kg
    func convertToKilograms(_ value: Double) -> Double {
        let measurement = Measurement(value: value, unit: preferredUnit)
        return measurement.converted(to: UnitMass.kilograms).value
    }
    
    // Format weight with proper unit symbol
    func formatWeight(_ kg: Double) -> String {
        let value = convertFromKilograms(kg)
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 1
        
        let measurement = Measurement(value: value, unit: preferredUnit)
        return formatter.string(from: measurement)
    }
    
    // Get the unit symbol (kg, lb)
    var unitSymbol: String {
        switch preferredUnit {
        case .kilograms:
            return "kg"
        case .pounds:
            return "lb"
        default:
            return "kg"
        }
    }
    
    // Get the unit name for display
    var unitName: String {
        switch preferredUnit {
        case .kilograms:
            return NSLocalizedString("unit.kg", comment: "kg unit")
        case .pounds:
            return NSLocalizedString("unit.lb", comment: "lb unit")
        default:
            return NSLocalizedString("unit.kg", comment: "kg unit")
        }
    }
    
    // Get the unit name for display (short)
    var unitNameShort: String {
        switch preferredUnit {
        case .kilograms:
            return "kg"
        case .pounds:
            return "lb"
        default:
            return "kg"
        }
    }
}

