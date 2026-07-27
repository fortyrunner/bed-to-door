import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @Environment(\.modelContext) private var modelContext

    @State private var step = 0
    @State private var activityLevel: ActivityLevel = .veryLittle
    @State private var usageReason: UsageReason = .other
    @State private var hasGarminWatch = false

    var body: some View {
        VStack(spacing: 24) {
            switch step {
            case 0:
                welcomeStep
            case 1:
                activityLevelStep
            default:
                permissionsAndSafetyStep
            }
        }
        .padding()
        .animation(.default, value: step)
    }

    private var welcomeStep: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("bed to door")
                .font(.largeTitle.bold())
            Text("A tiny daily step goal that grows with you — starting from wherever you are today.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Get started") { step = 1 }
                .buttonStyle(.borderedProminent)
        }
    }

    private var activityLevelStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Which sounds most like you?")
                .font(.title2.bold())

            ForEach(ActivityLevel.allCases, id: \.self) { level in
                Button {
                    activityLevel = level
                } label: {
                    HStack {
                        Text(level.rawValue)
                        Spacer()
                        if activityLevel == level {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }

            Toggle("I use a Garmin watch", isOn: $hasGarminWatch)
                .padding(.top)

            Spacer()
            Button("Continue") { step = 2 }
                .buttonStyle(.borderedProminent)
        }
    }

    private var permissionsAndSafetyStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Before you start")
                .font(.title2.bold())

            Label("This app reads your step count from Apple Health. It never talks to a watch or app directly.", systemImage: "heart.text.square")

            if hasGarminWatch {
                Label("Since you use a Garmin: open Garmin Connect → More → Settings → Connected Apps → Apple Health, and turn on step sharing so your steps show up here.", systemImage: "applewatch")
            }

            Label("The exercises in this app are not medical advice. Check with a doctor or physical therapist before starting, and stop if anything hurts.", systemImage: "cross.case")
                .foregroundStyle(.secondary)

            Spacer()

            Button("Allow Health access & continue") {
                Task {
                    await HealthKitManager.shared.requestAuthorization()
                    finishOnboarding()
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Skip for now") {
                finishOnboarding()
            }
            .buttonStyle(.plain)
        }
    }

    private func finishOnboarding() {
        let profile = UserProfile(
            activityLevel: activityLevel.rawValue,
            usageReason: usageReason.rawValue,
            hasGarminWatch: hasGarminWatch
        )
        modelContext.insert(profile)

        ExerciseLibrary.seedIfNeeded(context: modelContext)

        let today = Calendar.current.startOfDay(for: .now)
        let firstGoal = StepGoalRecord(date: today, goalValue: StepGoalEngine.defaultStartingGoal)
        modelContext.insert(firstGoal)

        hasCompletedOnboarding = true
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
        .modelContainer(for: [UserProfile.self, Exercise.self, StepGoalRecord.self], inMemory: true)
}
