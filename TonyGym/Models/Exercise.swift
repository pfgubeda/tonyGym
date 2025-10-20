import Foundation
import SwiftData

enum ExerciseCategory: Int, Codable, CaseIterable, Identifiable {
    case pierna = 1
    case pecho
    case espalda
    case hombro
    case brazos
    case core
    case otros

    var id: Int { rawValue }
    var displayName: String {
        switch self {
        case .pierna: return "Pierna"
        case .pecho: return "Pecho"
        case .espalda: return "Espalda"
        case .hombro: return "Hombro"
        case .brazos: return "Brazos"
        case .core: return "Core"
        case .otros: return "Otros"
        }
    }
}

@Model
final class ImageAttachment {
    @Attribute(.externalStorage) var data: Data
    var createdAt: Date
    @Relationship var exercise: Exercise?

    init(data: Data, createdAt: Date = .now) {
        self.data = data
        self.createdAt = createdAt
    }
}

@Model
final class Exercise {
    var title: String
    var details: String
    var defaultWeightKg: Double
    var categoryRaw: Int
    @Relationship(deleteRule: .cascade, inverse: \ImageAttachment.exercise) var images: [ImageAttachment]
    
    var createdAt: Date
    var updatedAt: Date

    var category: ExerciseCategory {
        get { ExerciseCategory(rawValue: categoryRaw) ?? .otros }
        set { categoryRaw = newValue.rawValue }
    }

    init(title: String, details: String = "", defaultWeightKg: Double = 0.0, category: ExerciseCategory = .otros, images: [ImageAttachment] = []) {
        self.title = title
        self.details = details
        self.defaultWeightKg = defaultWeightKg
        self.categoryRaw = category.rawValue
        self.images = images
        self.createdAt = .now
        self.updatedAt = .now
    }
}


