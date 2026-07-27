import Foundation
import SwiftData

/// A single strengthening exercise from the v1 starter set. No
/// equipment beyond a sturdy chair, a wall, or something already in
/// the kitchen.
@Model
final class Exercise {
    @Attribute(.unique) var id: String
    var name: String
    var instructions: String
    var targetReps: Int
    var sortOrder: Int
    var isEnabled: Bool

    init(id: String, name: String, instructions: String, targetReps: Int, sortOrder: Int, isEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.instructions = instructions
        self.targetReps = targetReps
        self.sortOrder = sortOrder
        self.isEnabled = isEnabled
    }
}
