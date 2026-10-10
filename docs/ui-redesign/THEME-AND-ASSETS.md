# Theme and cat assets

The first implementation stage adds `CatTheme.swift` and `CatIllustrationView.swift` to the app target. The theme defines dynamic light/dark colors, six compatible accent choices, rounded Dynamic Type typography, spacing, corner radii and reusable card/summary-row components. Existing saved color codes are unchanged. Navigation, tabs, setup surfaces, table surfaces and the start button use the theme. The setup and add-preset screens display the sitting cat; the other poses are ready for later screen redesigns.

## Artwork

Built-in ImageGen generated each pose separately with actual transparent backgrounds. Asset catalog names: `CatSitting`, `CatSleeping`, `CatStretching`, `CatPlayful`. `CatIllustrationView(pose:)` uses aspect-fit, original colors and decorative accessibility behavior. The same art works in light and dark mode; no separate dark assets are required. Existing `Catodoro` artwork and app icons are preserved.

Final prompt set: one prompt per pose using this template:

> Create one standalone transparent-background illustration asset for Catodoro iOS app. A charming ginger tabby cat [pose]. Consistent identity: rounded head, small triangular ears, cream muzzle/chest/paw tips, warm orange fur with darker soft orange tabby stripes, little dark brown nose, fine brown whiskers. Cozy premium flat editorial illustration with subtle soft shading, clean edges and rounded shapes, like the ginger cats in a tasteful cream/teal productivity app. Whole body centered, generous 10% transparent padding, isolated cat only, no plants, ground, shadows outside silhouette, letters, props, border, watermark or background. Readable at 100pt size on both charcoal and cream surfaces. Square composition.

Pose substitutions:

- sitting upright with tail curled around front paws, content closed-eye smile
- curled up sleeping peacefully with head on front paws and tail wrapped around body
- stretching with front paws extended forward, chest low, hindquarters lifted and tail curved upward
- lying on its back playfully with paws raised and curved tail

Image generation supplies original raster art, not exported components from the reference mockups. Native selection sheets and full screen layout changes remain in later milestones.

## Verification

Final simulator test build succeeded. All 20 focused tests passed: theme contrast and artwork loading, start button, setup view, subtitle, and option-selection controller. Every accent/on-accent pair meets a 4.5:1 contrast ratio in both appearances. All four artwork PNGs have an alpha channel and are 1254 × 1254 pixels.

The broad unit-test attempt stalled in `BaseNavigationControllerTests` and was stopped. Full-suite validation remains incomplete. Focused tests were rerun after updating obsolete styling assertions and stabilizing shared accent instances.

Small-iPhone simulator screenshots: [Light](verification/theme-light.png), [Dark](verification/theme-dark.png). Existing inline picker layout remains scrollable; the planned compact routine rows and selection sheets are a later milestone.

Visual QA also found and removed `SceneDelegate` forcing dark mode. The final app build passed after changing this to system appearance. The small-iPhone screenshots verify light mode and switching the running app to dark mode.

## Coat-color update

The user's cat photo replaces the ginger palette reference. All four poses are recolored through built-in ImageGen edits, preserving pose, expression, style and transparency. Final edit prompt: use the illustration as the edit target and the photo only as a coat-color reference; match very pale desaturated sandy beige/cream buff fur, subtle darker taupe-beige stripes, ivory muzzle/chest/paws and muted pink nose/inner ears; avoid saturated orange/yellow; preserve silhouette, proportions, composition, whiskers and transparent padding; exclude the photographed bed and surroundings. The original screenshot/reference boards above show the earlier ginger palette.

## Slimmer faces and timer artwork

All four existing poses were edited with built-in ImageGen to reduce exaggerated puffy cheeks and broad heads by approximately 25%, with a modest muzzle and softly tapered face while retaining each pose, expression and cream-tabby palette.

Two new transparent landscape assets are included: `CatFocus` (an attentive resting cat with open hazel eyes) and `CatBreak` (a curled sleeping cat). Generation prompts specify the cream-tabby identity, narrow natural cheeks, a compact low horizontal silhouette, transparent padding and no ring/text/plants/background. The supplied circle crop was used only as a composition reference. Assets are stored in `Catodoro/Assets.xcassets/CatFocus.imageset/CatFocus.png` and `CatBreak.imageset/CatBreak.png` and are available as `.focus` and `.timerBreak` in `CatPose`.

`TimerView` displays the companion below the countdown inside the existing circle. `TimerViewController` chooses the pose using `TimerViewModel.isBreak`, preserving it while paused. The main countdown is shifted upward to leave room for artwork.

## Cat beds and circular clipping

`CatFocus` and `CatBreak` now include a plush oval bed based on the user's cat-bed photo: light oatmeal exterior with a cream-white fleece interior and inner rim. The cat colors, slender faces and awake/sleeping expressions are preserved. Built-in ImageGen edit prompts added the same low, broad donut bed to each pose while retaining transparent backgrounds and excluding scenery, text and timer rings.

The PNG assets retain the full bed. `TimerView` clips the illustration at runtime with a circular shape mask matching the inner edge of the progress ring. The bed extends below the mask so its bottom follows the timer circle, while the progress stroke and countdown remain outside the masked container.
