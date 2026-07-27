import Foundation

/// The adaptive step-goal ramp described in the product spec: goals
/// start low, nudge upward on consistency, and pull back if the user
/// is missing them for several days running. A rolling look-back
/// window, not a fixed multi-week program — deliberately simpler than
/// something like Couch to 5k.
enum StepGoalEngine {
    static let defaultStartingGoal = 50
    static let minimumGoal = 10
    static let rampPercentage = 0.10
    static let minimumRampStep = 10
    static let lookbackWindow = 4
    static let hitsRequiredToRamp = 3
    static let consecutiveMissesToPullBack = 3

    /// `history` must be ordered oldest-to-newest, one record per day,
    /// each with the goal that was active and (once known) the actual
    /// steps recorded that day.
    static func nextGoal(currentGoal: Int, history: [StepGoalRecord]) -> Int {
        let recent = Array(history.suffix(lookbackWindow))

        let hits = recent.filter { record in
            guard let actual = record.actualSteps else { return false }
            return actual >= record.goalValue
        }.count

        if recent.count >= lookbackWindow, hits >= hitsRequiredToRamp {
            let increase = max(minimumRampStep, Int(Double(currentGoal) * rampPercentage))
            return currentGoal + increase
        }

        let recentMisses = Array(history.suffix(consecutiveMissesToPullBack))
        let allMissed = recentMisses.count == consecutiveMissesToPullBack && recentMisses.allSatisfy { record in
            guard let actual = record.actualSteps else { return false }
            return actual < record.goalValue
        }

        if allMissed {
            let lastConsistentGoal = history
                .dropLast(consecutiveMissesToPullBack)
                .last(where: { record in
                    guard let actual = record.actualSteps else { return false }
                    return actual >= record.goalValue
                })?.goalValue

            return max(minimumGoal, lastConsistentGoal ?? max(minimumGoal, currentGoal / 2))
        }

        return currentGoal
    }
}
