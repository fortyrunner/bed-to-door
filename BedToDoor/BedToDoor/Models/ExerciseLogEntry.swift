import Foundation
import SwiftData

/// One manual "I did it" completion of one exercise. Since an exercise
/// can be prescribed multiple times a day, this is a log of individual
/// occurrences rather than a single done/not-done flag per day — the
/// count of same-day entries for an exercise is how many times it's
/// been done today. Unlike steps, there is no HealthKit-backed source
/// of truth for this, so it lives entirely in the app's local store.
@Model
final class ExerciseLogEntry {
    var exerciseId: String
    var completedAt: Date

    init(exerciseId: String, completedAt: Date = .now) {
        self.exerciseId = exerciseId
        self.completedAt = completedAt
    }
}
