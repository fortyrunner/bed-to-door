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
    /// How many times per day this exercise should be done, e.g. 2 for
    /// "chair stands, twice a day". User-adjustable; defaults to once.
    /// The inline `= 1` matters beyond Swift's own default-argument
    /// convenience: SwiftData reads it during lightweight migration to
    /// backfill this column on rows that predate the field existing.
    var timesPerDay: Int = 1

    init(id: String, name: String, instructions: String, targetReps: Int, sortOrder: Int, isEnabled: Bool = true, timesPerDay: Int = 1) {
        self.id = id
        self.name = name
        self.instructions = instructions
        self.targetReps = targetReps
        self.sortOrder = sortOrder
        self.isEnabled = isEnabled
        self.timesPerDay = timesPerDay
    }
}
