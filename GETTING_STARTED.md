# Getting started

Open `BedToDoor.xcodeproj` in Xcode 16 or later. Requires iOS 17+ as the deployment target (already set).

## Before it'll run on your account

In the project settings → Signing & Capabilities, set your own Team and change `PRODUCT_BUNDLE_IDENTIFIER` (currently the placeholder `com.example.bedtodoor`) to something under your own domain. The HealthKit capability and entitlement are already configured, but Xcode needs a real team selected to provision it.

Since HealthKit step data doesn't really exist in the Simulator, run on a physical iPhone to see real numbers. The Simulator will build and launch fine, it'll just show 0 steps.

## What's here

`BedToDoorApp.swift` is the app entry point and SwiftData container setup. `Views/` holds Onboarding, Home (today's ring + exercise card), Exercises, History (now expandable per day, with manual step entry), and Settings. `Models/` holds the four SwiftData models (`UserProfile`, `StepGoalRecord`, `Exercise` — with a `timesPerDay` field, `ExerciseLogEntry` — one row per completion rather than one row per day). `Services/` holds `HealthKitManager` (the only thing that talks to HealthKit — now requests share/write access in addition to read, so it can save a manually entered step count as a normal HealthKit sample), `StepGoalEngine` (the adaptive ramp math from the spec), `ExerciseLibrary` (the five starter exercises), `DailyGoalService` (runs on launch to backfill yesterday's steps and compute today's goal), and `NotificationManager` (reminders — schedulable multiple times a day across a chosen window, not just once).

This matches `SPEC.md` at the repo root — that's the source of truth for *why* things work this way; this is the *how*.

## Honesty about this skeleton

This was hand-built without access to Xcode or a Swift compiler, so it hasn't been built or run. The project file was generated programmatically and validated structurally (parsed cleanly with a third-party Xcode project parser, correct file/group/build-phase wiring), but that's not the same as a compile. Treat this as a strong starting skeleton, not a guaranteed one-tap build — the first thing worth doing is opening it in Xcode and fixing whatever small thing complains, before building on top of it.

A few things to double check once it's open: that HealthKit's authorization prompt actually appears on first launch and now asks for both read and write access (both usage-description strings are already in the build settings), that the source-priority behavior mentioned in the spec (Garmin vs. phone vs. watch double-counting) behaves the way we expect, and that a manually entered step count in History actually shows up in the Health app afterward as a "bed to door" source — all three are flagged as worth testing, not something this skeleton could verify on its own.

One thing worth trying deliberately: since the app now requests HealthKit *write* access (previously it only read), if you already granted permissions on a build from before this change, iOS may not re-prompt automatically. If the manual step entry silently fails, check Settings → Privacy & Security → Health → BedToDoor on the device/simulator and confirm "Step Count" is toggled on under both categories.

## Not yet built

Anything from SPEC.md's "out of scope for v1" list: no accounts, no social features, no watch companion, no filmed/photographed/animated exercise content — a small per-exercise animation was tried and removed since it wasn't landing well visually; plain-text instructions are the v1 presentation. The adaptive ramp for exercise reps (vs. steps) is also left as a fixed target for now, and the walking reminder fires on a fixed schedule rather than reacting to how much the user has actually walked that day — both are flagged as open questions in the spec, not decided yet.

Note on the newer changes (repeatable exercises, multi-times-a-day reminders): these were written the same way as the rest of the skeleton — by hand, without a Swift compiler available — but validated by re-parsing the whole project file after each change to confirm nothing broke structurally. Same caveat as before: worth a first build in Xcode before assuming it's all correct.
