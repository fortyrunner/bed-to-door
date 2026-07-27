import Foundation
import HealthKit

/// The single point of contact with HealthKit. The app never queries a
/// device directly (no CMPedometer, no Garmin SDK) — HealthKit is the
/// one source of truth for step counts, regardless of whether they
/// came from the phone's motion coprocessor, an Apple Watch, Garmin
/// Connect's Apple Health sync, or a manual entry logged from this app.
/// HealthKit's own source-priority handling — not app logic — is what
/// resolves overlap between them.
@MainActor
final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    enum ManualEntryError: Error {
        case unavailable
    }

    private let healthStore = HKHealthStore()
    @Published var isAuthorized = false

    private var stepCountType: HKQuantityType {
        HKQuantityType(.stepCount)
    }

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async {
        guard isHealthDataAvailable else { return }
        do {
            // Read, to show progress toward the goal. Share (write), so a
            // day someone forgot their phone or watch can still be logged
            // — as a normal HealthKit sample, not a second local ledger.
            try await healthStore.requestAuthorization(toShare: [stepCountType], read: [stepCountType])
            isAuthorized = true
        } catch {
            isAuthorized = false
        }
    }

    /// Logs a manually-reported step count for a day, as an ordinary
    /// HealthKit sample flagged "user entered." This keeps HealthKit as
    /// the single source of truth: the manual entry sums into the same
    /// `stepCount(for:)` query as any other source, rather than living
    /// in a separate local total the app has to reconcile itself.
    func saveManualSteps(_ steps: Int, on day: Date) async throws {
        guard isHealthDataAvailable else { throw ManualEntryError.unavailable }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: day)
        let midday = calendar.date(byAdding: .hour, value: 12, to: startOfDay) ?? startOfDay
        // Never timestamp a sample in the future.
        let start = min(midday, .now)
        let end = start.addingTimeInterval(60)

        let quantity = HKQuantity(unit: .count(), doubleValue: Double(steps))
        let sample = HKQuantitySample(
            type: stepCountType,
            quantity: quantity,
            start: start,
            end: end,
            metadata: [HKMetadataKeyWasUserEntered: true]
        )
        try await healthStore.save(sample)
    }

    /// Cumulative step count for a single calendar day, summed across
    /// every HealthKit source.
    func stepCount(for day: Date) async -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: day)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return 0
        }
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepCountType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, _ in
                let steps = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(steps))
            }
            healthStore.execute(query)
        }
    }

    func todayStepCount() async -> Int {
        await stepCount(for: .now)
    }
}
