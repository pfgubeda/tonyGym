import Foundation
import SwiftData

// MARK: - Enums

enum MealType: Int, Codable, CaseIterable, Identifiable {
    case breakfast = 1
    case lunch
    case dinner
    case snack

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .breakfast: return NSLocalizedString("nutrition.meal.breakfast", comment: "Breakfast")
        case .lunch: return NSLocalizedString("nutrition.meal.lunch", comment: "Lunch")
        case .dinner: return NSLocalizedString("nutrition.meal.dinner", comment: "Dinner")
        case .snack: return NSLocalizedString("nutrition.meal.snack", comment: "Snack")
        }
    }

    var iconName: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "leaf.fill"
        }
    }
}

enum FoodEntrySource: Int, Codable {
    case manual = 1
    case barcode = 2
}

// MARK: - FoodEntry

@Model
final class FoodEntry {
    var date: Date
    var name: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var quantity: Double // grams or portions
    var mealTypeRaw: Int
    var sourceRaw: Int
    var barcode: String?

    var mealType: MealType {
        get { MealType(rawValue: mealTypeRaw) ?? .snack }
        set { mealTypeRaw = newValue.rawValue }
    }

    var source: FoodEntrySource {
        get { FoodEntrySource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }

    init(
        date: Date = .now,
        name: String,
        calories: Double,
        protein: Double,
        carbs: Double = 0,
        fat: Double = 0,
        quantity: Double = 100,
        mealType: MealType = .lunch,
        source: FoodEntrySource = .manual,
        barcode: String? = nil
    ) {
        self.date = date
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.quantity = quantity
        self.mealTypeRaw = mealType.rawValue
        self.sourceRaw = source.rawValue
        self.barcode = barcode
    }
}

// MARK: - NutritionGoal

@Model
final class NutritionGoal {
    var dailyCalories: Double
    var dailyProtein: Double
    var updatedAt: Date

    init(dailyCalories: Double = 2000, dailyProtein: Double = 120, updatedAt: Date = .now) {
        self.dailyCalories = dailyCalories
        self.dailyProtein = dailyProtein
        self.updatedAt = updatedAt
    }
}

// MARK: - FavoriteFood

@Model
final class FavoriteFood {
    var name: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var per100g: Bool // true = values are per 100g, false = per serving
    var usageCount: Int

    init(
        name: String,
        calories: Double,
        protein: Double,
        carbs: Double = 0,
        fat: Double = 0,
        per100g: Bool = true,
        usageCount: Int = 0
    ) {
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.per100g = per100g
        self.usageCount = usageCount
    }
}
