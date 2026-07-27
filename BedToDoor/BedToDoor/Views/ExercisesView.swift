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

    private func exerciseRow(for exercise: Exercise) -> some View {
        let today = Calendar.current.startOfDay(for: .now)
        let done = logEntries.contains {
            $0.exerciseId == exercise.id && $0.completed && Calendar.current.isDate($0.date, inSameDayAs: today)
        }

        return DisclosureGroup {
            Text(exercise.instructions)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.vertical, 4)

            Button(done ? "Marked done for today" : "Mark done for today") {
                toggle(exercise, done: !done)
            }
            .disabled(done)
        } label: {
            HStack {
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(done ? Color.green : Color.secondary)
                VStack(alignment: .leading) {
                    Text(exercise.name)
                    Text("\(exercise.targetReps) reps")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func toggle(_ exercise: Exercise, done: Bool) {
        let today = Calendar.current.startOfDay(for: .now)
        if let existing = logEntries.first(where: {
            $0.exerciseId == exercise.id && Calendar.current.isDate($0.date, inSameDayAs: today)
        }) {
            existing.completed = done
        } else {
            modelContext.insert(ExerciseLogEntry(date: today, exerciseId: exercise.id, completed: done))
        }
    }
}

#Preview {
    ExercisesView()
        .modelContainer(for: [Exercise.self, ExerciseLogEntry.self], inMemory: true)
}
