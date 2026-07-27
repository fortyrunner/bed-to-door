# Getting started

Open `BedToDoor.xcodeproj` in Xcode 16 or later. Requires iOS 17+ as the deployment target (already set).

## Before it'll run on your account

In the project settings → Signing & Capabilities, set your own Team and change `PRODUCT_BUNDLE_IDENTIFIER` (currently the placeholder `com.example.bedtodoor`) to something under your own domain. The HealthKit capability and entitlement are already configured, but Xcode needs a real team selected to provision it.

Since HealthKit step data doesn't really exist in the Simulator, run on a physical iPhone to see real numbers. The Simulator will build and launch fine, it'll just show 0 steps.

## What's here

`BedToDoorApp.swift` is the app entry point and SwiftData container setup. `Views/` holds Onboarding, Home (today's ring + exercise card), Exercises, History, and Settings. `Models/` holds the four SwiftData models (`UserProfile`, `StepGoalRecord`, `Exercise`, `ExerciseLogEntry`). `Services/` holds `HealthKitManager` (the only thing that talks to HealthKit), `StepGoalEngine` (the adaptive ramp math from the spec), `ExerciseLibrary` (the five starter exercises), `DailyGoalService` (runs on launch to backfill yesterday's steps and compute today's goal), and `NotificationManager` (the optional daily reminder).

This matches `SPEC.md` at the repo root — that's the source of truth for *why* things work this way; this is the *how*.

## Honesty about this skeleton

This was hand-built without access to Xcode or a Swift compiler, so it hasn't been built or run. The project file was generated programmatically and validated structurally (parsed cleanly with a third-party Xcode project parser, correct file/group/build-phase wiring), but that's not the same as a compile. Treat this as a strong starting skeleton, not a guaranteed one-tap build — the first thing worth doing is opening it in Xcode and fixing whatever small thing complains, before building on top of it.

A few things to double check once it's open: that HealthKit's authorization prompt actually appears on first launch (the usage-description string is already in the build settings), and that the source-priority behavior mentioned in the spec (Garmin vs. phone vs. watch double-counting) behaves the way we expect — that one's flagged as worth testing in the spec's open questions, not something this skeleton could verify on its own.

## Not yet built

Anything from SPEC.md's "out of scope for v1" list: no accounts, no social features, no watch companion. The adaptive ramp for exercises (vs. steps) is also left as a fixed target for now per the spec's open questions — worth deciding before that becomes automatic too.
