import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \StepGoalRecord.date, order: .reverse) private var goalRecords: [StepGoalRecord]
    @Query(sort: \Exercise.sortOrder) private var exercises: [Exercise]
    @Query private var logEntries: [ExerciseLogEntry]
    @StateObject private var healthKit = HealthKitManager.shared

    @State private var stepsByDay: [Date: Int] = [:]
    @State private var expandedDay: Date?
    @State private var manualStepsText = ""
    @State private var isSavingManualSteps = false
    @State private var manualStepsError: String?

    var body: some View {
        NavigationStack {
            List(goalRecords) { record in
                let day = Calendar.current.startOfDay(for: record.date)

                VStack(alignment: .leading, spacing: 0) {
                    Button {
                        toggle(day)
                    } label: {
                        dayRow(record: record, day: day)
                    }
                    .buttonStyle(.plain)

                    if expandedDay == day {
                        breakdown(for: day, record: record)
                            .padding(.top, 10)
                            .padding(.bottom, 6)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            .navigationTitle("History")
            .task { await loadRecentSteps() }
        }
    }

    private func toggle(_ day: Date) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedDay == day {
                expandedDay = nil
            } else {
                expandedDay = day
                manualStepsText = ""
                manualStepsError = nil
            }
        }
    }

    private func dayRow(record: StepGoalRecord, day: Date) -> some View {
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
                let exerciseCount = completions(for: day).count
                if exerciseCount > 0 {
                    Text("\(exerciseCount) exercise completion\(exerciseCount == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Image(systemName: expandedDay == day ? "chevron.up" : "chevron.down")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }

    private func completions(for day: Date) -> [ExerciseLogEntry] {
        logEntries.filter { Calendar.current.isDate($0.completedAt, inSameDayAs: day) }
    }

    @ViewBuilder
    private func breakdown(for day: Date, record: StepGoalRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            let steps = stepsByDay[day] ?? record.actualSteps ?? 0
            Label("\(steps) of \(record.goalValue) steps", systemImage: "figure.walk")
                .font(.subheadline)

            let enabledExercises = exercises.filter(\.isEnabled)
            if enabledExercises.isEmpty {
                Text("No exercises set up.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(enabledExercises) { exercise in
                    let count = completions(for: day).filter { $0.exerciseId == exercise.id }.count
                    let done = count > 0 && count >= exercise.timesPerDay
                    HStack {
                        Image(systemName: done ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(done ? Color.green : Color.secondary)
                        Text(exercise.name)
                            .font(.subheadline)
                        Spacer()
                        Text("\(count)/\(exercise.timesPerDay)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider()

            manualStepsEntry(for: day)
        }
        .padding(.leading, 2)
    }

    @ViewBuilder
    private func manualStepsEntry(for day: Date) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Forgot your watch or phone? Add steps for this day.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                TextField("Steps", text: $manualStepsText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)

                if isSavingManualSteps {
                    ProgressView()
                } else {
                    Button("Add") {
                        Task { await addManualSteps(for: day) }
                    }
                    .disabled(Int(manualStepsText) == nil)
                }
            }

            if let manualStepsError {
                Text(manualStepsError)
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
    }

    private func addManualSteps(for day: Date) async {
        guard let steps = Int(manualStepsText), steps > 0 else { return }
        isSavingManualSteps = true
        manualStepsError = nil
        do {
            try await healthKit.saveManualSteps(steps, on: day)
            stepsByDay[day] = await healthKit.stepCount(for: day)
            manualStepsText = ""
        } catch {
            manualStepsError = "Couldn't save to Health. Check Health access in Settings."
        }
        isSavingManualSteps = false
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
        .modelContainer(for: [StepGoalRecord.self, Exercise.self, ExerciseLogEntry.self], inMemory: true)
}
