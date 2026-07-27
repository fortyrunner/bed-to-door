import Foundation
import HealthKit

/// The single point of contact with HealthKit. The app never queries a
/// device directly (no CMPedometer, no Garmin SDK) — HealthKit is the
/// one source of truth for step counts, regardless of whether they
/// came from the phone's motion coprocessor, an Apple Watch, or Garmin
/// Connect's Apple Health sync. HealthKit's own source-priority
/// handling — not app logic — is what resolves overlap between them.
@MainActor
final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

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
            try await healthStore.requestAuthorization(toShare: [], read: [stepCountType])
            isAuthorized = true
        } catch {
            isAuthorized = false
        }
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
