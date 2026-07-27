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

    private func completionsToday(for exercise: Exercise) -> Int {
        let today = Calendar.current.startOfDay(for: .now)
        return logEntries.filter {
            $0.exerciseId == exercise.id && Calendar.current.isDate($0.completedAt, inSameDayAs: today)
        }.count
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
                        let done = completionsToday(for: exercise)
                        Text("\(exercise.targetReps) reps · \(done)/\(exercise.timesPerDay) today")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    let done = completionsToday(for: exercise)
                    let isComplete = done >= exercise.timesPerDay
                    Button {
                        logOne(for: exercise)
                    } label: {
                        Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    .disabled(isComplete)
                }
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func logOne(for exercise: Exercise) {
        modelContext.insert(ExerciseLogEntry(exerciseId: exercise.id, completedAt: .now))
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
