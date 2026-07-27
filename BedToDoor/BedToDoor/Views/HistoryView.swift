import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \StepGoalRecord.date, order: .reverse) private var goalRecords: [StepGoalRecord]
    @Query private var logEntries: [ExerciseLogEntry]
    @StateObject private var healthKit = HealthKitManager.shared

    @State private var stepsByDay: [Date: Int] = [:]

    var body: some View {
        NavigationStack {
            List(goalRecords) { record in
                let day = Calendar.current.startOfDay(for: record.date)
                HStack {
                    VStack(alignment: .leading) {
                        Text(day, style: .date)
                        Text("Goal: \(record.goalValue) steps")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        let steps = stepsByDay[day] ?? record.actualSteps ?? 0
                        Text("\(steps)")
                            .foregroundStyle(steps >= record.goalValue ? Color.green : Color.primary)
                        let exerciseCount = logEntries.filter {
                            Calendar.current.isDate($0.date, inSameDayAs: day) && $0.completed
                        }.count
                        if exerciseCount > 0 {
                            Text("\(exerciseCount) exercise\(exerciseCount == 1 ? "" : "s")")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("History")
            .task { await loadRecentSteps() }
        }
    }

    private func loadRecentSteps() async {
        for record in goalRecords.prefix(30) {
            let day = Calendar.current.startOfDay(for: record.date)
            if stepsByDay[day] == nil {
                stepsByDay[day] = await healthKit.stepCount(for: day)
            }
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [StepGoalRecord.self, ExerciseLogEntry.self], inMemory: true)
}
