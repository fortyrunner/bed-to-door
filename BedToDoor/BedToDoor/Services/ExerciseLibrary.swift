import Foundation
import SwiftData

/// The fixed v1 starter set of exercises, modeled on the NIA's Go4Life
/// program — a well-established, evidence-based exercise resource built
/// for older and deconditioned adults. Every move can be done holding a
/// chair or wall for balance, using a can of food or bottle of water
/// in place of a dumbbell. No equipment to buy.
enum ExerciseLibrary {
    static let starterSet: [(id: String, name: String, instructions: String, targetReps: Int)] = [
        (
            id: "chair_stand",
            name: "Chair Stand",
            instructions: "Sit toward the front of a sturdy chair. Stand up, using your arms for support if you need to, then sit back down slowly. That's one rep.",
            targetReps: 2
        ),
        (
            id: "seated_march",
            name: "Seated March",
            instructions: "Sit tall in a chair. Lift one knee, lower it, then lift the other. That's one rep.",
            targetReps: 4
        ),
        (
            id: "wall_pushup",
            name: "Wall Push-Up",
            instructions: "Stand facing a wall, hands flat against it at shoulder height. Bend your elbows to bring your chest toward the wall, then push back. That's one rep.",
            targetReps: 2
        ),
        (
            id: "can_curl",
            name: "Can or Bottle Curl",
            instructions: "Hold a can of food or a bottle of water in each hand. With arms at your sides, bend your elbows to bring your hands toward your shoulders, then lower slowly. That's one rep.",
            targetReps: 4
        ),
        (
            id: "calf_raise",
            name: "Calf Raise",
            instructions: "Stand holding a counter or the back of a chair for balance. Rise onto your toes, then lower slowly. That's one rep.",
            targetReps: 4
        )
    ]

    /// Seeds the starter set the first time the app runs. Safe to call
    /// repeatedly — it's a no-op once exercises already exist.
    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Exercise>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        for (index, entry) in starterSet.enumerated() {
            let exercise = Exercise(
                id: entry.id,
                name: entry.name,
                instructions: entry.instructions,
                targetReps: entry.targetReps,
                sortOrder: index
            )
            context.insert(exercise)
        }
    }
}
