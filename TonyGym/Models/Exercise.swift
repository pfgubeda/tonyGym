import Foundation
import SwiftData

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
    @Relationship(deleteRule: .cascade, inverse: \ImageAttachment.exercise) var images: [ImageAttachment]
    
    var createdAt: Date
    var updatedAt: Date

    init(title: String, details: String = "", defaultWeightKg: Double = 0.0, images: [ImageAttachment] = []) {
        self.title = title
        self.details = details
        self.defaultWeightKg = defaultWeightKg
        self.images = images
        self.createdAt = .now
        self.updatedAt = .now
    }
}


