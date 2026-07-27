import Foundation
import SwiftData

/// Runs on app launch to make sure "today" has a goal record,
/// backfilling actual step counts for past days first so the ramp
/// engine has real data to react to.
@MainActor
enum DailyGoalService {
    static func ensureTodayGoal(context: ModelContext) async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        let descriptor = FetchDescriptor<StepGoalRecord>(sortBy: [SortDescriptor(\.date, order: .forward)])
        let records = (try? context.fetch(descriptor)) ?? []

        guard !records.isEmpty else {
            context.insert(StepGoalRecord(date: today, goalValue: StepGoalEngine.defaultStartingGoal))
            return
        }

        for record in records where record.actualSteps == nil && record.date < today {
            record.actualSteps = await HealthKitManager.shared.stepCount(for: record.date)
        }

        guard (records.last?.date ?? today) < today else { return }

        let currentGoal = records.last?.goalValue ?? StepGoalEngine.defaultStartingGoal
        let nextGoal = StepGoalEngine.nextGoal(currentGoal: currentGoal, history: records)
        context.insert(StepGoalRecord(date: today, goalValue: nextGoal))
    }
}
