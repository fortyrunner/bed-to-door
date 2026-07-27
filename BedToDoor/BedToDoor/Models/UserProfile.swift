import Foundation
import SwiftData

enum ActivityLevel: String, Codable, CaseIterable {
    case veryLittle = "I move very little most days"
    case some = "I move a little, but it's inconsistent"
    case recovering = "I'm recovering from an illness, injury, or surgery"
}

enum UsageReason: String, Codable, CaseIterable {
    case recovery = "Recovering from something"
    case chronicIllness = "Managing a chronic illness"
    case deconditioning = "General deconditioning"
    case other = "Other / prefer not to say"
}

/// Onboarding answers, kept purely to tailor copy tone. Never gated
/// behind a medical disclaimer wall, never required.
@Model
final class UserProfile {
    var activityLevel: String
    var usageReason: String
    var hasGarminWatch: Bool
    var createdAt: Date

    init(activityLevel: String = ActivityLevel.veryLittle.rawValue,
         usageReason: String = UsageReason.other.rawValue,
         hasGarminWatch: Bool = false,
         createdAt: Date = .now) {
        self.activityLevel = activityLevel
        self.usageReason = usageReason
        self.hasGarminWatch = hasGarminWatch
        self.createdAt = createdAt
    }
}
