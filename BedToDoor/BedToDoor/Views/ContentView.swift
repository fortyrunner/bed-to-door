import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
    }
}

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Today", systemImage: "figure.walk") }
            ExercisesView()
                .tabItem { Label("Exercises", systemImage: "figure.strengthtraining.traditional") }
            HistoryView()
                .tabItem { Label("History", systemImage: "calendar") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .task {
            await DailyGoalService.ensureTodayGoal(context: modelContext)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [UserProfile.self, StepGoalRecord.self, Exercise.self, ExerciseLogEntry.self], inMemory: true)
}
