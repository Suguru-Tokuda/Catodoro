# Catodoro UI redesign project plan

Prepared October 10, 2026. Based on a source scan of the current working tree and the approved visual concepts. This document plans implementation; it does not implement the redesign.

## Goal and approved direction

Deliver a cohesive, cozy cat-themed app across Focus, active timer, Presets, and Settings, in light and dark mode. Use cream/charcoal surfaces, rounded typography, teal/mint controls, restrained ginger cat illustrations, and consistent rounded cards. Keep the existing UIKit architecture and coordinator navigation. The widget extension remains SwiftUI.

Reference boards: [Light mode](references/light-mode.png), [Dark mode](references/dark-mode.png), [Selection sheets](references/selection-sheets.png).

These images guide appearance and interaction. Their illustrated controls and placeholder labels are not production assets or final specifications. Implement native accessible controls; obtain individual cat assets separately. References were generated with the built-in ImageGen tool. Prompt direction: cohesive four-screen cat-themed iOS redesign; matching warm dark mode; three modal selection sheets with duration wheels and a session stepper.

## What the project scan found

| Area | Current implementation | Consequence for the redesign |
| --- | --- | --- |
| App structure | UIKit views/controllers, Combine view models, coordinators | Extend existing components; no framework rewrite needed. |
| Focus setup | `TimerConfigView` embeds two `TimerPickerView` instances and a sessions wheel | Replace inline wheels with three tappable summary rows and present sheets from controllers. |
| Shared setup | `AddPresetViewController` also uses `TimerConfigView` | Both entry points must use the same sheet behavior and configuration rendering. |
| Duration picker | Hours 0–23, minutes/seconds 0–59; supports programmatic configuration | Reuse and adapt the wheels; preserve seconds support. |
| Configuration | `TimerConfigModel` defaults to zero focus, zero break, one session; validity checks only positive focus | Introduce explicit useful defaults and validate duration bounds and 1–20 sessions. |
| Active timer | `TimerView` has a fixed 250-point ring, time text and icon buttons | Add responsive composition, phase labels, session indicators and state-specific controls. |
| Theme | Earlier working-tree changes add `CatTheme`, a drawn cat, warmer colors and larger controls | Treat this as a preliminary pass; centralize the theme rather than layering more scattered styles. |
| Presets | Core Data saves ID, durations and count; no name field; plain table rows | Named presets require a versioned schema migration. Existing records need fallback display names. |
| Settings | Color and sound selection screens with stored preferences | Inline color swatches and current-value rows can reuse preference storage; Live Activity toggle is new work. |
| Assets | Existing `Catodoro` image, app icon and six color assets | Inspect existing artwork before reuse; approved mockup cats are not yet separate assets. |
| Live Activity | SwiftUI extension with hardcoded green/red controls | Match compact presentation and colors without crowding system surfaces. |
| Testing | Numerous component/unit tests; UI tests largely launch/performance scaffolding | Update tests affected by view replacement and add meaningful end-to-end selection flows. |
| Build setup | Deployment values include 17.5 and 18.2; test targets use 18.2 | Validate on a compatible simulator; check target/file membership when adding UIKit files. |

Working tree already contains timer/UI modifications and an untracked `TestViewController.swift`. Preserve those files and review the existing diff before implementation. Prior verification reported a successful app build and 13 passing timer tests; this planning scan did not rerun them or establish a full-suite baseline.

## Interaction specification

### Focus setup and duration sheets

- First-launch routine: 25-minute focus, 5-minute break, four focus sessions. Initialize UI and model from the same configuration. Keep the last confirmed routine while navigating within the app; persistence across relaunch is outside the initial scope.
- Show Focus time, Catnap break and Sessions as accessible summary rows, plus total routine duration and Start focusing.
- Tapping either duration row presents a native modal bottom sheet via `UISheetPresentationController`. Keep the dimmed setup screen visible. Use a content-appropriate detent; allow a larger detent and scrolling for accessibility text sizes and compact layouts.
- Initialize Hours, Minutes and Seconds wheels from the committed value. Keep a local draft while editing; do not mutate the routine as the wheels scroll.
- Focus shortcuts: 15, 25 and 50 minutes. Break shortcuts: No break, 5 and 10 minutes. A shortcut replaces the entire draft duration, including seconds, and updates wheel positions.
- Set focus time / Set break time commits once, refreshes the corresponding row and total summary, then dismisses. Zero focus disables confirmation with explanatory text. Zero break is valid and displays No break.
- Close, swipe-down and other cancellation dismissals discard draft values. Reopening shows the last committed value. No full-screen push for these selections.
- iPad uses a centered, width-constrained modal appropriate to the presentation environment; landscape and compact height can expand the sheet to fit controls.

### Sessions sheet

- Title Focus sessions; large count with minus/plus controls, minimum one and maximum 20. Disable the corresponding control at each boundary. VoiceOver announces count and changes.
- Draft count is initialized from the committed routine. Use paw indicators for small counts; for larger counts use a compact count summary rather than twenty cramped icons.
- Show focus subtotal, break subtotal and total duration using shared formatting/calculation code. Formula: focus duration × sessions + break duration × (sessions − 1). One session or zero break has no break time.
- Set sessions commits once. Closing or swiping discards the draft. A 25/5 routine with four sessions totals 1 hr 55 min.

### Active timer

- Preserve pushed timer navigation and the current hidden-tab behavior during a routine.
- Show Focus session n of N or Catnap break n of N−1, responsive progress ring, readable remaining time, cat illustration and compact paw indicators.
- Distinct states: running focus, running break, paused, completed. Running offers Pause and End session; paused offers Resume and End session; completion offers Focus again and Back to routine.
- Render countdown as mm:ss below one hour and h:mm:ss for longer durations. Expose a useful accessibility value without announcing every timer tick.
- Keep logical timer state authoritative. Ring progress must reconcile with remaining duration after background/foreground transitions and interruption, rather than relying solely on a running animation.
- Reduce Motion disables decorative movement. Cat illustrations are decorative and excluded from VoiceOver.

### Presets and Settings

- Presets use rounded cards with name, duration/break/session summary, illustration and an accessible start action. Preserve swipe-to-delete. Include an empty state with Create preset and recoverable load/save/delete errors.
- Add Preset remains a pushed screen, with a name field and the same three setup rows/sheets. Save validates, prevents duplicate submissions, and reports failure without dismissing.
- Add a versioned Core Data model with an optional preset name; migrate existing records safely and show a duration-derived fallback name. Do not silently seed demo presets or overwrite user data.
- Settings displays six color choices with a visible selected indicator, current timer sound, and matching grouped surfaces. Preserve existing color codes and sound IDs. Replace mockup Soft bell with a real bundled sound label unless a new sound is explicitly added.
- Follow the system appearance in the first release. Light and dark variants apply to all screens and sheets; color preference controls accent, not appearance mode.
- Live Activity switch requires an actual stored preference and behavior: turning it off ends the current activity without stopping the timer; turning it on while playing starts an activity when system authorization permits. Show unavailable/disabled system status clearly. Do not ship a decorative switch.

## Implementation milestones

### 1. Establish the baseline and theme foundations

Dependencies: none.

- Review existing changes; run the full unit suite and document pre-existing failures separately.
- Move `CatTheme` out of `BaseView.swift` into a dedicated theme module. Define dynamic surface, card, primary/secondary text, accent/on-accent, separator and selected-state colors, plus spacing, radii and typography.
- Make all six accents usable in both modes. Preserve stored codes; reconcile existing asset colors with the new central theme. Verify contrast rather than assuming a pastel is suitable for button text.
- Create reusable card, setting/summary row and button styles with Dynamic Type and at least 44-point touch targets. Style navigation/tab bars consistently and retain existing routes.
- Produce individual sitting, sleeping, stretching and playful cat assets with transparent backgrounds, appropriate scale/resolution and asset catalog entries. Use a shared illustration component with bounded dimensions and optional dark-mode variants. Keep the existing drawn cat as a temporary fallback.

Primary files: `Views/General/BaseView.swift`, `ViewControllers/General/BaseViewController.swift`, `BaseNavigationController.swift`, `Enums/ColorOptions.swift`, `Coordinators/TabCoordinator.swift`, `Assets.xcassets`.

Done when: tokens/components preview correctly in both modes, system appearance changes update visible surfaces, and baseline build/tests are recorded.

### 2. Build shared routine state and selection sheets

Dependencies: milestone 1.

- Add shared routine summary calculation/formatting and complete validation to `TimerConfigViewModel`/`TimerConfigModel`.
- Add `DurationSelectionViewController` with a focus/break mode, existing configured wheels, shortcuts, draft value, cancel and commit callbacks.
- Add `SessionSelectionViewController` with count stepper, bounds and draft summary. Keep presentation and ownership in controllers/coordinators; views emit selection requests.
- Use the same presenters from Focus and Add Preset. Register new files in the correct target.
- Attach event handlers once rather than during `layoutSubviews`; ensure selections, rendered rows and underlying model stay synchronized.

Done when: Set commits, every cancel path discards, reopening restores values, shortcuts synchronize wheels, invalid focus is blocked, and limits/summary math pass tests.

### 3. Replace the Focus setup screen

Dependencies: milestones 1–2.

- Replace embedded picker stacks with cat hero, heading, routine card, three tappable rows, total summary and Start focusing.
- Initialize a valid default routine; render from state after every confirmed edit. Reuse the setup layout in Add Preset with appropriate Save copy and name input.
- Support compact phones, iPad, landscape, long duration text and accessibility text sizes using scrollable content and readable maximum widths.

Primary files: `TimerConfigView.swift`, `TimerConfigViewController.swift`, `TimerConfigViewModel.swift`, `AddPresetViewController.swift`.

Done when: all three sheets are reachable and reflect their confirmed selections, Start uses exactly the displayed routine, and both modes match the approved visual hierarchy.

### 4. Redesign the active timer and its state rendering

Dependencies: milestones 1 and 3.

- Expose a consistent presentation state from `TimerViewModel` containing phase, index/count, remaining duration and progress; avoid separate views independently inferring state from text.
- Rebuild `TimerView`/`TimerCircleView` around responsive layout, ring, illustration, phase header, indicators and labeled controls.
- Preserve timer fixes already in the working tree; test pause/resume, phase transition, zero break, completion, repeat and exit behavior.
- Review lifecycle handling: `BaseViewController.onFinish` currently fires on every disappearance. Sheet presentation and timer navigation must not accidentally signal routine completion or reveal tabs.

Done when: screen and ring stay synchronized during pauses and app return, every timer state has the correct action, and exit returns to setup with tabs restored.

### 5. Redesign Presets and finish preset creation

Dependencies: milestones 1–3; schema migration precedes named cards.

- Version the data model; update `PresetModel`, Core Data mapping/save, mocks and fixtures for optional names.
- Replace `PresetListViewCell` layout with accessible cards; add empty/loading/error states and accurate summaries.
- Remove duplicated setup in `PresetsViewController.viewDidLoad` and correct `setupConstraints` calling `super.setupSubviews`.
- Keep save/delete/load UI updates on the main actor. Replace silent save errors and review completion callbacks and weak-reference handling.

Done when: existing saved records survive upgrade, new named presets persist, starting a preset uses its stored values, and empty/error/delete cases are usable in both modes.

### 6. Redesign Settings and Live Activity surfaces

Dependencies: milestone 1; activity preference behavior depends on stable timer integration from milestone 4.

- Rebuild grouped settings with mascot, inline accent swatches and selected sound value; retain sound-selection navigation and preview behavior.
- Add Live Activity preference, protocol/mocks and authorization-aware presentation. Gate activity creation and handle toggling during a routine.
- Address the blocking semaphore in `LiveActivityManager.endLiveActivity` and errors thrown inside an unawaited Task in `startLiveActivity`; use an explicit asynchronous lifecycle before adding another UI entry point.
- Restyle Live Activity/Dynamic Island labels and controls with compact cat/paw accents. Keep relevant shared tokens/assets available to the extension; do not import UIKit-only app components into widget code.

Done when: preferences persist, changing accent updates visible UI, activity toggle is functional, denied authorization is handled, and activity controls still work.

### 7. Visual QA, accessibility and release checks

Dependencies: all previous milestones.

- Capture deterministic screenshots for all main screens and all three sheets in light/dark, including paused/break/completed timer and empty/error preset states.
- Compare screenshots with reference boards on small and large iPhones and iPad. Check keyboard handling on preset naming, sheet detents, safe areas and landscape.
- Check VoiceOver order/labels/values, large Dynamic Type, Reduce Motion, contrast and non-color selection indicators.
- Replace tests tied to removed picker hierarchies with behavior tests. Add end-to-end flows for Set/cancel/reopen, routine start, preset creation/relaunch/delete and persisted settings.
- Run full unit/UI checks on compatible runtimes; build app, shared target and widget extension. Verify Live Activity on a supported device because simulator screenshots alone cannot establish its complete behavior.

Done when: no unresolved regressions introduced by the redesign, no clipping or constraint conflicts in the QA matrix, and all visible controls operate as specified.

## Suggested delivery order and scope

Deliver milestones as reviewable changes: theme/assets → shared sheets → Focus → active timer → Presets → Settings/widget → QA. Keep each stage buildable. Do not mix a UIKit-to-SwiftUI rewrite, statistics, streaks, onboarding, notifications, cloud sync or preset sharing into this project.

Named presets and the Live Activity preference are included because the approved boards show them, but they are functional extensions rather than styling-only tasks. Deliver theme and sheets first; do not let these extensions block review of the main design. Exact calendar estimates should be set after the baseline test run and standalone illustration assets are ready.

## Release acceptance checklist

- [ ] Focus, active timer, Presets, Settings and selection sheets share the approved visual language in both appearances.
- [ ] Duration and session edits are transactional: Set saves, cancellation preserves prior values.
- [ ] One to twenty sessions, seconds precision and No break work; all total summaries use the same formula.
- [ ] Timer phases, progress, pauses, background return, completion and navigation remain correct.
- [ ] Existing presets/preferences survive upgrade; new preset names persist; failures are recoverable.
- [ ] System appearance and all six accents remain readable and update correctly.
- [ ] Live Activity preference and widget controls behave correctly, including unavailable authorization.
- [ ] Accessibility and small-screen/iPad visual checks pass; full validation evidence is recorded.
