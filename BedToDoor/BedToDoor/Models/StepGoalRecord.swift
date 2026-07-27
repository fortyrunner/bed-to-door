import Foundation
import SwiftData

/// One entry per day a goal value took effect. This — not raw step
/// counts, which live in HealthKit — is the local history the adaptive
/// ramp engine and the History screen read from.
@Model
final class StepGoalRecord {
    var date: Date
    var goalValue: Int
    var actualSteps: Int?

    init(date: Date, goalValue: Int, actualSteps: Int? = nil) {
        self.date = date
        self.goalValue = goalValue
        self.actualSteps = actualSteps
    }
}
