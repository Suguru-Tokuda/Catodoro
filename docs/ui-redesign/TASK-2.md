# Task 2: shared routine state and selection sheets

Implemented October 10, 2026.

## Behavior

Focus setup and Add Preset use the same three tappable rows and shared native sheet presenter. New setup view models start with 25-minute focus, 5-minute break and four sessions. The underlying model initializer retains its existing empty defaults for explicit callers; the new standard configuration is the single source for setup defaults.

Duration sheets initialize hours, minutes and seconds from the confirmed configuration. Focus shortcuts are 15/25/50 minutes; break shortcuts are No break/5/10 minutes. Each shortcut replaces the entire duration, including seconds. Zero focus disables Set; zero break is valid.

The sessions sheet edits a local count between one and twenty, disables controls at the limits and displays focus, break and total subtotals. Only breaks between sessions count toward the total. Four 25/5 sessions total 1 hr 55 min.

Set commits once and refreshes the rows and total. Close and native swipe dismissal discard drafts. Sheets reopen from the confirmed configuration. Both entry points share these semantics.

Duration sheets start at a 520-point detent and sessions at 580 points, bounded by available height, with a large detent available. Set stays pinned above the bottom safe area while content scrolls. Accessibility text sizes open at the large detent and stack duration shortcuts vertically. iPad requests a centered form sheet with a 500-point preferred width.

## Fixes included

- Validate every duration component and the session count; reject invalid preset configurations at the save boundary.
- Assign event handlers once, replacing picker mutation during layout.
- Remove duration picker closure retain cycles.
- Report controller completion only when leaving navigation or being dismissed, rather than whenever another screen covers it.
- Register the new controllers and tests in their Xcode targets. New files use the requested author headers and UI properties use initializer closures for fixed styling.

## Validation

- App, shared framework and widget simulator build passed.
- 31 focused unit/regression tests passed: routine validation and summaries, draft/confirmation semantics, session limits, picker ownership, setup rendering, Add Preset and timer view model behavior.
- The end-to-end sheet flow passed in light mode on iPhone 18 Pro / iOS 27 and dark mode on a separate iPhone 16 / iOS 18.2 simulator. It checks close/cancel/reopen, shortcuts, No break, session confirmation, swipe cancellation, and edits from Add Preset. Test attachments contain all three sheet screenshots.
- Final light and dark screenshots reviewed for visible controls and confirmation buttons. The review caught clipped confirmation controls in the initial half-height layout; taller detents and pinned confirmation controls resolved it.
- `git diff --check` passed.

The full test suite was not run. iPad, landscape, VoiceOver and the full accessibility-size/device matrix remain part of milestone 7. The existing deployment mismatch warning (app 17.5 versus shared framework 18.2) remains outside this change.

## Next

Task 3 completes the Focus hero, heading, grouped routine card and responsive screen layout. The minimal summary rows delivered here make Task 2 usable from both setup entry points. Preset naming and recoverable persistence errors remain in Task 5.

## Custom paw asset

The sessions sheet uses the `CatPaw` template image from `Catodoro/Assets.xcassets/CatPaw.imageset/CatPaw.png`. Each indicator represents exactly one paw, replacing the paired-paw emoji. The transparent template follows the theme's teal/mint accent. Counts above six retain the compact text summary.

Generated with the built-in ImageGen tool using this prompt:

> Use case: logo-brand. Asset type: custom cat paw UI icon for a cozy cat-themed iOS focus timer. Generate exactly ONE single upright cat paw print centered on a square transparent canvas: one softly rounded three-lobed central pad and exactly four separate oval toe pads above it, balanced slightly organic shapes, clear gaps. Flat solid black silhouette with crisp clean edges, legible at 24 pixels, minimal friendly rounded design. Paw occupies approximately 85 percent of canvas with consistent small padding. Genuine transparent background. No second paw, no pair of footprints, no trail, no actual furry foot, no outline, no gradients, no shadow, no texture, no text, no border or decorative objects. The app will tint this alpha silhouette teal in light mode and mint in dark mode.

## Alignment with the approved modal design

The three sheets now use an illustrated header and upper-right Close button. Focus uses CatStretching; Catnap break and Sessions reuse the approved cream/beige cat assets. Duration wheels precede the shortcut chips, and an exact duration match selects the corresponding chip with a solid accent background. A custom duration with seconds clears chip selection.

The sessions stepper and individual paw indicators sit in a mint card. An outlined card underneath shows Focus duration × sessions, Break duration × intervening breaks, and a bold total. The helper labels explain the 1–20 limit and that breaks happen between sessions. Rounded filled stepper controls and capsule confirmation buttons follow the reference while retaining native sheets, scrolling and draft confirmation behavior.

Modal alignment verification: simulator build, ten routine tests (including selected shortcut behavior), and end-to-end sheet flows passed. Light and dark appearances were reviewed; the compact final sessions height was checked in light mode.

## Architecture follow-up

`DurationSelectionView`, `RoutineSelectionView`, and `SessionSelectionView` own the sheet controls, styling, constraints, and presentation updates. Controllers instantiate their root view and connect interaction callbacks; duration draft, shortcut selection, validation, and confirmation remain in `DurationSelectionViewModel`.
