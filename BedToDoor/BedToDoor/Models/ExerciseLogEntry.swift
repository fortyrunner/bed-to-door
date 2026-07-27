import Foundation
import SwiftData

/// A manual "I did it" log entry for one exercise on one day. Unlike
/// steps, there is no HealthKit-backed source of truth for this, so it
/// lives entirely in the app's local store.
@Model
final class ExerciseLogEntry {
    var date: Date
    var exerciseId: String
    var completed: Bool

    init(date: Date, exerciseId: String, completed: Bool = true) {
        self.date = date
        self.exerciseId = exerciseId
        self.completed = completed
    }
}
