import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query(sort: \StepGoalRecord.date, order: .reverse) private var goalRecords: [StepGoalRecord]
    @Environment(\.modelContext) private var modelContext

    @StateObject private var healthKit = HealthKitManager.shared

    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderCount") private var reminderCount = 1
    @AppStorage("reminderStartHour") private var reminderStartHour = 9
    @AppStorage("reminderEndHour") private var reminderEndHour = 19

    @State private var manualGoalText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Remind me to walk", isOn: $reminderEnabled)
                        .onChange(of: reminderEnabled) { _, enabled in
                            if enabled {
                                Task {
                                    await NotificationManager.requestAuthorization()
                                    scheduleReminders()
                                }
                            } else {
                                NotificationManager.cancelAllReminders()
                            }
                        }

                    if reminderEnabled {
                        Stepper(
                            "\(reminderCount) time\(reminderCount == 1 ? "" : "s") a day",
                            value: $reminderCount,
                            in: 1...NotificationManager.maxRemindersPerDay
                        )
                        .onChange(of: reminderCount) { _, _ in scheduleReminders() }

                        DatePicker(
                            "Starting around",
                            selection: startHourBinding,
                            displayedComponents: .hourAndMinute
                        )
                        .onChange(of: reminderStartHour) { _, _ in scheduleReminders() }

                        if reminderCount > 1 {
                            DatePicker(
                                "Ending around",
                                selection: endHourBinding,
                                displayedComponents: .hourAndMinute
                            )
                            .onChange(of: reminderEndHour) { _, _ in scheduleReminders() }
                        }
                    }
                } header: {
                    Text("Reminders")
                } footer: {
                    if reminderEnabled {
                        Text(reminderCount == 1
                             ? "One nudge a day, around the time above."
                             : "\(reminderCount) nudges, spread evenly between the two times above.")
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

    private var startHourBinding: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = reminderStartHour
                components.minute = 0
                return Calendar.current.date(from: components) ?? .now
            },
            set: { newValue in
                reminderStartHour = Calendar.current.component(.hour, from: newValue)
            }
        )
    }

    private var endHourBinding: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = reminderEndHour
                components.minute = 0
                return Calendar.current.date(from: components) ?? .now
            },
            set: { newValue in
                reminderEndHour = Calendar.current.component(.hour, from: newValue)
            }
        )
    }

    private func scheduleReminders() {
        NotificationManager.scheduleReminders(
            count: reminderCount,
            startHour: reminderStartHour,
            endHour: max(reminderStartHour, reminderEndHour)
        )
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
