import SwiftUI
import SwiftData

struct ExercisesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.sortOrder) private var exercises: [Exercise]
    @Query private var logEntries: [ExerciseLogEntry]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("Not medical advice. Check with a doctor or physical therapist before starting, and stop if anything hurts.", systemImage: "cross.case")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                ForEach(exercises.filter(\.isEnabled)) { exercise in
                    exerciseRow(for: exercise)
                }
            }
            .navigationTitle("Exercises")
        }
    }

    private func completionsToday(for exercise: Exercise) -> Int {
        let today = Calendar.current.startOfDay(for: .now)
        return logEntries.filter {
            $0.exerciseId == exercise.id && Calendar.current.isDate($0.completedAt, inSameDayAs: today)
        }.count
    }

    private func exerciseRow(for exercise: Exercise) -> some View {
        let doneCount = completionsToday(for: exercise)
        let isComplete = doneCount >= exercise.timesPerDay

        return DisclosureGroup {
            VStack(spacing: 16) {
                Text(exercise.instructions)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Stepper(
                    "Do this \(exercise.timesPerDay) time\(exercise.timesPerDay == 1 ? "" : "s") a day",
                    value: Binding(
                        get: { exercise.timesPerDay },
                        set: { exercise.timesPerDay = max(1, $0) }
                    ),
                    in: 1...6
                )
                .font(.subheadline)

                HStack {
                    Text("\(doneCount) of \(exercise.timesPerDay) done today")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if doneCount > 0 {
                        Button("Undo last") {
                            undoLast(for: exercise)
                        }
                        .font(.footnote)
                    }
                }

                Button(isComplete ? "All done for today" : "Log one") {
                    logOne(for: exercise)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isComplete)
            }
            .padding(.vertical, 8)
        } label: {
            HStack {
                Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isComplete ? Color.green : Color.secondary)
                VStack(alignment: .leading) {
                    Text(exercise.name)
                    Text("\(exercise.targetReps) reps · \(doneCount)/\(exercise.timesPerDay) today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func logOne(for exercise: Exercise) {
        modelContext.insert(ExerciseLogEntry(exerciseId: exercise.id, completedAt: .now))
    }

    private func undoLast(for exercise: Exercise) {
        let today = Calendar.current.startOfDay(for: .now)
        let todaysEntries = logEntries
            .filter { $0.exerciseId == exercise.id && Calendar.current.isDate($0.completedAt, inSameDayAs: today) }
            .sorted { $0.completedAt > $1.completedAt }

        if let mostRecent = todaysEntries.first {
            modelContext.delete(mostRecent)
        }
    }
}

#Preview {
    ExercisesView()
        .modelContainer(for: [Exercise.self, ExerciseLogEntry.self], inMemory: true)
}
