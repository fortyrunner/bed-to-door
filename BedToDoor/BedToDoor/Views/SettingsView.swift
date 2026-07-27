import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query(sort: \StepGoalRecord.date, order: .reverse) private var goalRecords: [StepGoalRecord]
    @Environment(\.modelContext) private var modelContext

    @StateObject private var healthKit = HealthKitManager.shared

    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderHour") private var reminderHour = 18
    @AppStorage("reminderMinute") private var reminderMinute = 0

    @State private var manualGoalText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Daily reminder") {
                    Toggle("Remind me once a day", isOn: $reminderEnabled)
                        .onChange(of: reminderEnabled) { _, enabled in
                            if enabled {
                                Task {
                                    await NotificationManager.requestAuthorization()
                                    scheduleReminder()
                                }
                            } else {
                                NotificationManager.cancelDailyReminder()
                            }
                        }
                    if reminderEnabled {
                        DatePicker(
                            "Time",
                            selection: reminderTimeBinding,
                            displayedComponents: .hourAndMinute
                        )
                        .onChange(of: reminderHour) { _, _ in scheduleReminder() }
                        .onChange(of: reminderMinute) { _, _ in scheduleReminder() }
                    }
                }

                Section("Step goal") {
                    if let current = goalRecords.first {
                        Text("Current goal: \(current.goalValue) steps/day")
                    }
                    TextField("Set a new goal manually", text: $manualGoalText)
                        .keyboardType(.numberPad)
                    Button("Update goal") {
                        updateGoalManually()
                    }
                    .disabled(Int(manualGoalText) == nil)
                }

                Section("Health access") {
                    Label(
                        healthKit.isAuthorized ? "Connected to Apple Health" : "Not connected",
                        systemImage: healthKit.isAuthorized ? "checkmark.circle.fill" : "exclamationmark.circle"
                    )
                    Button("Re-request Health access") {
                        Task { await healthKit.requestAuthorization() }
                    }
                }

                Section("About") {
                    Text("bed to door helps you go from very little daily movement to a bit more, at a pace that adjusts to you. Once your goal grows past a few thousand steps, consider graduating to a standard walking or running program.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }

    private var reminderTimeBinding: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = reminderHour
                components.minute = reminderMinute
                return Calendar.current.date(from: components) ?? .now
            },
            set: { newValue in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                reminderHour = components.hour ?? 18
                reminderMinute = components.minute ?? 0
            }
        )
    }

    private func scheduleReminder() {
        var components = DateComponents()
        components.hour = reminderHour
        components.minute = reminderMinute
        NotificationManager.scheduleDailyReminder(at: components)
    }

    private func updateGoalManually() {
        guard let newGoal = Int(manualGoalText), newGoal > 0 else { return }
        let today = Calendar.current.startOfDay(for: .now)
        modelContext.insert(StepGoalRecord(date: today, goalValue: newGoal))
        manualGoalText = ""
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [UserProfile.self, StepGoalRecord.self], inMemory: true)
}
