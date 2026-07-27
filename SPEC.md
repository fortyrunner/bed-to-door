# bed-to-door — Product Spec (v0.1)

## The problem

Couch to 5k and similar apps are built for people who can already walk comfortably and just need training structure. They're intimidating or irrelevant to someone walking under 500 steps a day — often due to chronic illness, disability, deconditioning, depression, or long recovery from injury or surgery. For this person, "go for a 20-minute walk" isn't a stretch goal, it's a non-starter. This app's job is the step before that: get someone from essentially not moving to reliably moving a little, every day, without triggering shame or overwhelm.

## Target user

Someone currently averaging fewer than 500 steps/day who wants to move more but has been burned by fitness apps that assume a baseline of mobility and motivation they don't have. They may be managing chronic pain, fatigue, mental health conditions, or simply deep deconditioning after a sedentary stretch. The app should feel more like a physical therapist's home program than a fitness app.

## Design principles

Research on step-count interventions (e.g. the MoveMore field study, JMIR 2026 trials on physical activity apps) shows a consistent pattern: gamification and social competition produce short-term step bumps that often don't hold up once the novelty fades, while simpler interventions — goal-setting, self-monitoring, tailored feedback — tend to sustain better, especially for people who aren't already primed to enjoy competition. That points to a specific set of principles for this app:

Goals must be trivially achievable at the start, even if that means absurdly low (25–50 steps). The whole mechanic depends on the user never facing a goal that feels hard on day one. Progress should ramp automatically and slowly based on actual behavior, not a fixed program the user has to opt into or configure. The tone should be neutral-to-warm, never guilt-based — no red "you failed" states, no streak-shaming. Streaks are acknowledged, not weaponized. Gamification should be light and optional (badges, not leaderboards) rather than central, since competitive/social mechanics are the part of prior interventions that didn't hold up long-term. And the app should stay usable on a bad day: missing a day or several days should lead to a gentle re-entry point, not a reset that punishes the user for the thing that's already hardest for them.

## Input sources: device-agnostic by design

What matters is steps walked, not what recorded them. Someone might have an Apple Watch, a Garmin, or nothing but the phone in their pocket, and the app should work equally well for all three without asking which one they have.

This falls out naturally from building on HealthKit rather than talking to any device directly. On the phone-only path, iOS itself already counts steps via the motion coprocessor (the same data `CMPedometer` exposes) and writes them into HealthKit automatically — no watch needed, and nothing extra for the app to build. Apple Watch step data also lands in HealthKit automatically once paired. Garmin doesn't write to HealthKit by default, but Garmin Connect has a first-party "share with Apple Health" setting (Garmin Connect → More → Settings → Connected Apps → Apple Health) that, once the user turns it on, pushes Garmin's step count into HealthKit just like any other source. So the app never needs a Garmin SDK or any device-specific integration — it reads one thing, HealthKit's daily step total, regardless of where it came from.

Two practical implications for onboarding and settings. First, if the user has a Garmin, onboarding should include a one-line pointer to enable Garmin Connect's Apple Health sharing, since that step happens inside Garmin's app, not ours, and is easy to miss. Second, when a phone and a watch (or Garmin) are both logging steps for the same period, HealthKit's own "Data Sources & Access" priority list resolves which source wins for a given day rather than the app summing both and double-counting — worth a settings-screen link out to that HealthKit panel, and worth explicit testing during implementation to confirm the merge behaves as expected before relying on it.

There's a fourth source, too: the person themselves. Someone who forgot their phone or watch on a walk should still be able to log it — from History, they can add a step count for that day, which the app writes into HealthKit as an ordinary sample flagged "user entered" rather than tracking it in a separate local total. That keeps the "one source of truth" property intact: a manual entry sums into the same daily total as any device source, rather than becoming a second number the app has to reconcile against HealthKit's.

## Core mechanic: adaptive step ramp

Each user gets a single daily step goal, not a multi-week fixed program. The goal starts very low (default 50 steps, user can lower it further) and adjusts based on a rolling window of recent performance rather than a rigid schedule:

If the user hits their goal for 3 of the last 4 days, the goal increases by a small amount (roughly 10%, rounded, with a sensible floor like +10 steps minimum). If the user misses their goal for 3+ days running, the goal decreases back toward a level they were last consistently hitting — the app never lets the gap between "goal" and "recent reality" grow large enough to feel discouraging. There's a soft ceiling logic once someone approaches ~3,000–5,000 steps/day, at which point the app can suggest graduating to a more standard program (a natural handoff point to something like Couch to 5k), rather than trying to be the only app they ever need.

This is deliberately simpler than a fixed 9-week program: no missed-week catch-up logic to design, no user having to restart a plan, and it self-calibrates to whatever is happening in someone's life that month.

## Strengthening exercises (companion to steps)

Steps alone don't rebuild the strength this audience often also loses — the ability to get up from a chair unassisted, reach a cupboard, keep balance. The NIA's Go4Life program (a well-established, evidence-based exercise resource built specifically for older and deconditioned adults) is built around exactly this idea, and explicitly uses things like a can of vegetables or a bottle of water in place of dumbbells — validating the "tins of beans" instinct directly. This app should borrow that model rather than inventing exercise science from scratch.

A few things distinguish this from a normal workout feature. No equipment beyond a sturdy chair, a wall, and something already in the kitchen (a can of food, a bottle of water) — never anything the user would need to buy. It's optional and separate from the step goal, so a day where exercise doesn't happen still leaves the step win intact; they're two small wins, not one combined bar that can fail on two fronts. It starts at a genuinely trivial level (e.g. "2 chair stands") and stays manually logged rather than auto-detected, since motion data can reliably tell us someone walked but can't reliably tell us they did a chair stand — a simple "I did it" tap is the whole interaction. And it needs a plain, upfront safety line: this isn't medical advice, check with a doctor or physical therapist before starting anything new, stop if something hurts. That matters more here than in a generic fitness app given how many people in this audience are managing an existing condition.

Starter set (all can be done holding a chair or wall for balance, no floor work):

Chair stand — sit-to-stand from a chair, using arms for support if needed. The single highest-value exercise for this group since it's the movement behind most daily transfers.
Seated marches — lifting knees one at a time while seated.
Wall push-ups — hands on wall, standing, for upper body without any floor work.
Arm raises or curls holding a can of food or bottle of water in each hand.
Calf raises holding a counter or chair back for balance.

Like the step goal, reps should start absurdly low (2, not 10) with headroom to ramp later — though whether that ramp should be automatic like steps, or stay fixed for v1 given the manual-logging signal is noisier, is worth deciding during implementation rather than locking in now (see open questions).

Exercises are also repeatable within a day, not just once. PT-style home programs are commonly prescribed as "twice a day," not once, so each exercise has its own times-per-day count (defaulting to once, user-adjustable) rather than a single daily checkbox. Logging reflects this directly: each tap records one completion with a timestamp, and the day's status is "2 of 3 done" rather than done/not-done — with an undo for the most recent tap in case of a mis-tap, since there's no automatic detection to fall back on.

A small animated illustration per exercise was tried and pulled back out — plain-text instructions are staying as the v1 presentation (see "out of scope" below).

## MVP feature set

Onboarding asks minimal questions: current rough activity level (a few plain-language options, not a form), and optionally a reason for using the app (recovery, chronic illness, general deconditioning, other) purely to tailor copy tone, never gated behind a medical disclaimer wall. Onboarding requests HealthKit/Motion permissions with a clear one-line explanation of why, and includes one plain-text safety line ahead of the exercise feature: not medical advice, check with a doctor or physical therapist before starting, stop if something hurts.

The home screen shows today's goal, today's progress toward it, and a small optional "today's exercise" card below it — and nothing else competing for attention beyond those two things. No feed, no social tab, no ads.

Automatic step tracking pulls from HealthKit (which already merges phone, Apple Watch, and — if the user enables Garmin Connect's Apple Health sharing — Garmin data) rather than the app trying to do its own motion sensing or talk to any device directly. No watch is required; phone-only step counting works out of the box.

History view shows a simple calendar/bar view of past days vs goal, so users can see the trend without it turning into a performance review. Tapping a day expands it into a breakdown — steps vs goal, and each exercise's completions that day — and tapping again collapses it; only one day is expanded at a time, so it stays a light accordion rather than everything unfolding at once. The expanded view is also where manual step entry lives: a small "forgot your watch or phone? add steps for this day" field, for any day in the list, not just today.

Gentle reminders are time-of-day nudges the user configures, off by default until the user opts in. Rather than a single fixed time, the user sets how many times a day they'd like a nudge (1 up to a small cap, e.g. 6) plus a start and end time, and the app spaces that many reminders evenly across the window — e.g. "3 times a day, between 9am and 7pm" lands nudges around 9, 2, and 7. One reminder a day remains the default and simplest case; the multi-per-day option exists for people whose routine is closer to "get up and move every couple of hours" than "one walk a day."

Light positive reinforcement: milestone acknowledgments (first day hitting goal, first week, first goal increase) as simple non-intrusive moments, no points economy, no in-app currency.

A "graduate" prompt appears once someone's goal has climbed past a threshold, pointing them toward standard walking/running programs — this app should be honest about being a starting point, not a lifetime destination.

## Explicitly out of scope for v1

No social features, friends, or leaderboards — the research on sustained behavior change plus this audience's likely sensitivity to comparison argues against it. No account system or login for MVP; local-first with HealthKit as the source of truth avoids a backend entirely for v1. No video, photographed, or animated exercise demonstrations, and no large exercise library — plain-text instructions are enough to start; a simple animated illustration was tried and removed for not landing well, and richer demonstrations (illustrated or filmed) are a good v2 candidate if revisited with more design attention. No automatic rep detection or motion-based exercise tracking — logging is a manual tap. No exercises requiring equipment beyond a chair, a wall, or something already in the kitchen. No direct device integrations (no Garmin SDK, no watch-specific code) — everything comes through HealthKit as the single aggregation point. No monetization/paywall in v1.

## Screens

Onboarding (2–3 short screens plus permission requests, including the exercise safety disclaimer), Home (today's step goal + progress, plus today's exercise card showing "x of y" per exercise), Exercises (the small starter list, plain-text instructions, a per-exercise times-per-day setting, and tap-to-log/undo), History (list of past days, each expandable on tap into a steps + per-exercise breakdown, plus manual step entry for a forgotten watch or phone), Settings (reminder count + time window, manually adjust goal, HealthKit permission status, about/graduate info).

## Data model (local, HealthKit-backed)

The app doesn't need to store step counts itself — those live in HealthKit and are queried on demand via `HKStatisticsQuery` (cumulative sum, per day). What the app does need to persist locally (e.g. via `SwiftData` or a small local store) is: current step goal value, step goal history (date + value, so the ramp logic and history view have something to reference even if HealthKit data is sparse), reminder preferences (count per day, start/end window), onboarding/profile answers (activity level, stated reason) purely for copy personalization, and — for exercises — the current exercise set with its per-exercise target reps and times-per-day, plus a log of individual completion events (exercise + timestamp, one row per "I did it" tap rather than one row per day) so a single day can hold more than one completion per exercise. Unlike steps, this data has no HealthKit-backed source of truth and lives entirely in the app.

## Tech stack

Native SwiftUI, targeting a recent iOS baseline (iOS 17+) to use modern SwiftUI/SwiftData cleanly. Step data via HealthKit only (`HKQuantityTypeIdentifierStepCount`, `HKStatisticsQuery` with `.cumulativeSum`) — never a direct `CMPedometer` query and never a device-specific SDK. HealthKit is the single source of truth regardless of whether steps originated from the phone's motion coprocessor, an Apple Watch, Garmin Connect's Apple Health sync, or a manual entry, and its own source-priority system (not app logic) resolves conflicts between overlapping sources. The app requests both read and share (write) authorization for step count — read to show progress, share so manual entries can be saved as `HKQuantitySample`s tagged `HKMetadataKeyWasUserEntered`, which requires an `NSHealthUpdateUsageDescription` alongside the existing read-access string. Local persistence via SwiftData for goal state and preferences. Notifications via `UserNotifications`, scheduling anywhere from one to a handful of daily reminders spaced across a user-chosen window. No backend needed for v1.

## Open questions before implementation

Should the reason/profile answers from onboarding actually change copy/tone (more implementation work, better fit) or just be collected for future use? Should there be any Apple Watch companion (complication showing today's progress) in v1, or is iPhone-only fine for a first build? What should the exact ramp math be — the 3-of-4-days / 10% figures above are a reasonable starting guess but worth sanity-checking against a physical therapist or occupational therapist if you have access to one, given the target audience. For exercises specifically: should rep targets ramp automatically like steps, or stay fixed for v1 given manual logging is a weaker signal than HealthKit data? Should users be able to swap out an individual exercise (e.g. skip wall push-ups if standing balance is an issue) rather than getting one fixed starter set? And is five exercises the right starting number, or should v1 launch with even fewer?

Now that both steps and exercises support a "how many times a day" setting, a couple of things are worth deciding once real usage data exists rather than now: whether the walking reminder should eventually respond to actual HealthKit activity (e.g. skip a nudge if the user's already near pace for the window) rather than firing on a fixed clock regardless of progress, and whether the per-exercise times-per-day count should itself ramp the way the step goal does, or stay a manually-set number indefinitely.

Manual step entry raises its own small question: self-reported numbers can inflate the adaptive ramp (a generous manual entry nudges tomorrow's goal up same as a real one), but treating manual entries with suspicion — capping them, flagging them differently in the ramp math — cuts against the app's whole stance of trusting the user rather than policing them. Left as-is for v1 (a manual entry counts exactly like any other), worth revisiting only if it turns out to be a real problem in practice rather than a hypothetical one.

---

Sources consulted: [MoveMore field study, JMIR](https://www.jmir.org/2021/4/e19875), [Physical activity behavior change techniques trial, JMIR 2026](https://www.jmir.org/2026/1/e73388), [CMPedometer/HealthKit overview](https://www.devfright.com/how-to-use-the-cmpedometer-for-counting-steps/), [Garmin Connect + Apple Health sync](https://support.garmin.com/en-US/?faq=lK5FPB9iPF5PXFkIpFlFPA), [NIA Go4Life exercise program](https://go4life.nia.nih.gov/exercise)
