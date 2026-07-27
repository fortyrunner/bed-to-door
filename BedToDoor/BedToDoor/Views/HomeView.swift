import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StepGoalRecord.date, order: .reverse) private var goalRecords: [StepGoalRecord]
    @Query(sort: \Exercise.sortOrder) private var exercises: [Exercise]
    @Query private var logEntries: [ExerciseLogEntry]

    @StateObject private var healthKit = HealthKitManager.shared
    @State private var todaySteps = 0
    @State private var isLoadingSteps = true

    private var todayGoal: Int {
        goalRecords.first?.goalValue ?? StepGoalEngine.defaultStartingGoal
    }

    private var progress: Double {
        guard todayGoal > 0 else { return 0 }
        return min(1.0, Double(todaySteps) / Double(todayGoal))
    }

    private var todaysCompletedExerciseIds: Set<String> {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        return Set(
            logEntries
                .filter { Calendar.current.isDate($0.date, inSameDayAs: startOfDay) && $0.completed }
                .map(\.exerciseId)
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    stepProgressCard
                    if !exercises.isEmpty {
                        exerciseCard
                    }
                }
                .padding()
            }
            .navigationTitle("Today")
            .task { await refreshSteps() }
            .refreshable { await refreshSteps() }
        }
    }

    private var stepProgressCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(.quaternary, lineWidth: 14)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack {
                    Text(isLoadingSteps ? "…" : "\(todaySteps)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                    Text("of \(todayGoal) steps")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 220, height: 220)

            if progress >= 1.0 {
                Text("Today's goal is done. Anything extra is a bonus.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var exerciseCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's exercise")
                .font(.headline)

            ForEach(exercises.filter(\.isEnabled)) { exercise in
                HStack {
                    VStack(alignment: .leading) {
                        Text(exercise.name)
                        Text("\(exercise.targetReps) reps")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    let done = todaysCompletedExerciseIds.contains(exercise.id)
                    Button {
                        toggleExercise(exercise, isDone: !done)
                    } label: {
                        Image(systemName: done ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func toggleExercise(_ exercise: Exercise, isDone: Bool) {
        let today = Calendar.current.startOfDay(for: .now)
        if let existing = logEntries.first(where: {
            $0.exerciseId == exercise.id && Calendar.current.isDate($0.date, inSameDayAs: today)
        }) {
            existing.completed = isDone
        } else {
            modelContext.insert(ExerciseLogEntry(date: today, exerciseId: exercise.id, completed: isDone))
        }
    }

    private func refreshSteps() async {
        isLoadingSteps = true
        todaySteps = await healthKit.todayStepCount()
        isLoadingSteps = false
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [StepGoalRecord.self, Exercise.self, ExerciseLogEntry.self], inMemory: true)
}
