# Task 5: named cat presets

Implemented October 11, 2026. The user chose a full screen editor and bundled cat illustrations.

## Behavior

- The timer hides the tab bar with UIKit’s `hidesBottomBarWhenPushed`; there is no manual tab-bar visibility change before the push. This keeps bottom safe-area changes coordinated with the navigation animation.
- Presets retains a child timer coordinator using its own navigation controller. Starting a preset keeps the Presets tab selected; exiting pops directly back to the list. Focus uses its separate timer coordinator.
- Preset cards show the chosen cat, name, focus/break/session summary and total routine duration. Tap the card to edit; the separate play control starts the saved routine. Swipe to delete remains available.
- New/edit preset uses a dedicated `PresetEditorView` and `PresetEditorViewModel`. The view model owns the draft, name validation, routine validation and persistence. The coordinator handles editor and image-picker navigation.
- A name is required for saving and surrounding whitespace is trimmed. Routine rows use the same transactional duration/session sheets as Focus. Returning without saving discards the draft.
- The image picker offers the six bundled cat illustrations. The stored identifier refers to an asset rather than duplicating image data.
- Save errors retain the draft for retry. The list has creation, loading and recoverable error states. UI updates after persistence run on the main actor.

## Persistence

The original Core Data model remains in the model bundle. `CatodoroCoreDataV2` adds optional String attributes `name` and `imageIdentifier`, with automatic lightweight migration enabled. Older presets retain their IDs and timing values and display a duration-based name and sitting cat. Editing saves using the existing ID, updating the record rather than inserting a duplicate. Unknown image identifiers fall back to the sitting cat.

## Validation

- 12 focused unit tests pass: editor validation, trimmed names, preserving IDs/timing during edits, failed-save recovery, migration of a legacy SQLite store, Core Data name/image round trips and deletion, card rendering/reuse/accessibility, and list delegation.
- The create/edit UI flow passed in light and dark mode: image selection, shared duration sheets, saving, reopening, editing, app relaunch persistence and starting the stored routine. The final light run also checks swipe deletion.
- iPhone 16 simulator screenshots inspected for editor, preset cards and image grid. Broader device sizes and accessibility sizes remain in Task 7.
- Existing deployment-target warnings are unchanged.
