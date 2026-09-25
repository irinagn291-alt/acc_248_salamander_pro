# Salamander — Build Specification

> Portfolio app 80, batch pending. This document is the complete brief for
> building this application. Read all of it before writing any code. Anything
> not specified here is your decision, but must stay consistent with section 3.

**One-line positioning:** Tap numbered cook steps on tonight's ticket.

| Field | Value |
| --- | --- |
| Product name | Salamander |
| Bundle identifier | `com.salamander.pass` |
| Domain | https://salamander-pass.pro |
| Contact URL | https://salamander-pass.pro/contact-us |
| Deployment target | iOS 17.0 |
| Swift version | 6.2, strict concurrency `complete` |
| Devices | iPhone and iPad, portrait |
| Interface style | Dark |
| Asset prefix | `slm_` |
| User-Agent | `Salamander/1.0 (iOS; +https://salamander-pass.pro)` |

---

## 1. Non-negotiable constraints

1. **No CocoaPods.** Dependencies come from Swift Package Manager, a local
   in-repo package, a vendored source folder, or nothing at all — per section 3.
2. **No shared code with other portfolio apps.** Business rules are re-implemented
   here under this app's own type names.
3. **All code, identifiers, comments, UI copy and the README are in English.**
4. **No launch gate, no WebView shell, no remote configuration, no analytics.**
   Guideline 4.2 (Minimum Functionality): this is a native SwiftUI product, not
   a web browsing experience. WKWebView / SFSafariViewController as UI is a
   reject. Push notifications, Core Location, and sharing do not make a
   browser or a thin catalog into an App Store app.
5. **Guideline 5.1.1 (Privacy):** never direct the user to grant camera access.
   A pre-permission screen may exist; the proceed button is **Continue** or
   **Next**, never "Allow camera", "Enable camera", "Grant camera", or a bare
   Allow/Enable that triggers `requestAccess`. The system alert is the only Allow.
6. **No CI files.** No `bitrise.yml`, no `Scripts/`, no `metadata/` folder.
7. **Assets are AI-generated.** No stock photography. SF Symbols may support
   small affordances but must never be the primary iconography.
8. **The app must build clean** with
   `xcodegen generate && xcodebuild -scheme Salamander -destination 'generic/platform=iOS' build`.
9. **Nothing may echo another app in this batch** in naming, layout or visuals.
10. **This is not a calorie meal-slot tracker** unless family is `food_tracker`.
   Do not invent food logging to fill the brief.

---

## 2. Product core

The product is offline-first. No account, no sign-in, no ads, no in-app purchase,
no analytics SDK, no remote config. All user data stays on the device.

A home cook taps the next fire walk on tonight's open ticket so the dish plates.

### 2.1 User flow

1. Tap the next fire walk on tonight's ticket
2. Retract the last walk if that tick was wrong
3. Search the catalog and save a recipe into the cookbook
4. After the dish plates, open a cookbook recipe onto the pass
5. Check mise bowls until FireMark starts the walks
6. Open Settings for catalog credit and data reset

### 2.2 Essential behaviour

- One open Ticket on the pass; mise bowls and fire walks fuse on Home
- Idle timer held only while the Ticket is Firing
- Cookbook of saved recipes; Search maps cgi search pl onto TheMealDB
- Empty or failed search falls back to the local cookbook shelf
- ServiceMark history, retract, and simulator seed with a live Walk
- No shop, no calories, no meal slots, no food barcode

---

## 3. Uniqueness assignment for Salamander

| Axis | Assigned value |
| --- | --- |
| Architecture | **Ticket ADT fold (Mise | Firing | Plated); the pass is a fold over Tickets; last Bowl writes a FireMark and holds idle; last Walk writes a ServiceMark and restores sleep; Walk index is the WalkMark count** |
| UI approach | **SwiftUI pure · take recipecook** |
| Naming convention | **Brigade / kitchen-pass lexicon** |
| File organization | **By pass role (Pass, Ticket, Bowl, Walk, FireMark, ServiceMark)** |
| Dependency strategy | **None** |
| Design direction | **Ink and paper mono** |
| Typography | **SF Pro** |
| Navigation pattern | **Pass-locked chrome (the open ticket never leaves; Search, Cookbook and Settings arrive as sheets; mise and fire fuse on Home)** |
| AI art style | **3D glass render glassmorphism · take recipecook** |
| Functional twist | **Mise-then-fire (last Bowl writes FireMark and flips Mise to Firing; Walks file the fire; last Walk writes ServiceMark and freezes; idle sleep is held only while Firing)** |
| Persistence | **UserDefaults+Codable** |
| Screen composition | see 3.6 |

### 3.0 Product concept

This is the product the contracts below are assigned to. Do not substitute another.

**Family** — recipe_cook

**Core** — A home cook taps the next fire walk on tonight's open ticket so the dish plates.

**Audience** — Home cooks who need numbered steps awake on the counter, not a recipe blog and not a shop.

**User flow**

1. Tap the next fire walk on tonight's ticket
2. Retract the last walk if that tick was wrong
3. Search the catalog and save a recipe into the cookbook
4. After the dish plates, open a cookbook recipe onto the pass
5. Check mise bowls until FireMark starts the walks
6. Open Settings for catalog credit and data reset

**Essential features**

- One open Ticket on the pass; mise bowls and fire walks fuse on Home
- Idle timer held only while the Ticket is Firing
- Cookbook of saved recipes; Search maps cgi search pl onto TheMealDB
- Empty or failed search falls back to the local cookbook shelf
- ServiceMark history, retract, and simulator seed with a live Walk
- No shop, no calories, no meal slots, no food barcode

**Twist** — Mise-then-fire. Home is tonight's ticket on the pass. Search saves a Recipe into the Cookbook. Opening a book item writes a Ticket as Mise. Checking a Bowl files it. The last Bowl writes a FireMark, flips Mise to Firing, and holds the idle timer so the screen does not sleep. Tapping a Walk writes a WalkMark. The last Walk writes a ServiceMark, flips Firing to Plated, and restores sleep. Retract peels the last Bowl or WalkMark. A second open while Firing is refused. Seed writes one Ticket already Firing so the next Walk is live. Home verb: walk-the-fire, not browse-a-feed. Cookbook counts ServiceMarks. No calories and no meal slots.

**Why this is not a repeat** — This is the first recipe_cook in the ledger. Home is walk-the-fire on one Ticket, not Speedwell's pour from seated bottles, not Deadwax crate-and-rate, not KcalCraft's per-100g builder, and not a food_tracker with slots or macros. Cook mode is the persisted verb: Mise then Firing then Plated, with idle held only while Firing. TheMealDB search is input; 4.2 is the native ticket, not a recipe website. Scanner and food barcodes stay unused.

### 3.0a Craft from the shipped portfolio

Full craft is in KNOWLEDGE.md. Follow it. Do not copy type names or layouts.
- Home: Cookbook + cook mode (do-not-sleep steps).
- Invariant: Cook mode: ingredients checked, then numbered steps. Dish-of-the-day is optional chrome.
- Never: Not a shop.
- Taste DNA is section 7.6. Do not invent a second look.
- A TabView with exactly three tabs is the factory stamp — use two or four-to-five destinations, or a different chrome. `-ReviewScreen today|log|goals` are launch keys, not tabs.

### 3.1 Architecture contract

A Ticket is an algebraic data type with phases Mise, Firing, and Plated. The pass is a fold over Tickets: one Ticket may be open, and plated Tickets remain only as ServiceMark history. Checking a Bowl files that Bowl; the last unfiled Bowl writes a FireMark, folds Mise to Firing, and sets the idle timer so the screen stays awake. Tapping a Walk writes a WalkMark; the Walk index is the WalkMark count and is never stored as a cursor. The last Walk writes a ServiceMark, folds Firing to Plated, and restores idle sleep. Retract peels the last Bowl or WalkMark and reverses the FireMark or ServiceMark that write caused; a second open while Firing is refused.

Put a short comment block at the top of each principal type stating the role it
plays in this architecture. The README must justify the pattern for this product.

### 3.2 UI contract

100 percent SwiftUI. The ui axis is SwiftUI pure with a recipecook take, so write a new pass composition and do not copy a holder layout. No UIViewRepresentable, no AVFoundation preview, no Safari sheet, and no WebView. Home is the mechanic: one open ticket fills the device, mise bowls and numbered fire walks fuse on the same surface, and iPad uses the width. Search, Cookbook, and Settings arrive as sheets over the pass; Cook is not a pushed scene. Native Button, Toggle, and TextField only; a tappable onTapGesture card fails. Primary actions use a ButtonStyle with default, pressed, disabled, and loading; Retract uses the destructive variant. Hit the whole chrome with contentShape and a minimum 44pt target. Colours, type, space, and radius each have one accessor and no raw hex or magic pt in views. Editorial ink on paper: rules, not cards; one masthead; the live Walk is the pull quote; adjacent home blocks do not share the same column structure. Quiet motion, 180ms cross-fade; Reduce Motion is an instant swap. One haptic on a successful Bowl, Walk, Save, or Retract; none on opening a sheet.

### 3.3 Naming contract

Convention: Brigade / kitchen-pass lexicon.

Examples to follow: `Ticket`, `Bowl`, `WalkMark`, `FireMark`

### 3.4 Dependency contract

None. project.yml has no packages key. No SPM, no CocoaPods, no bundled font, no Alamofire. Foundation, SwiftUI, and URLSession only. Do not import AVFoundation or Vision. The leftover AVCaptureMetadataOutput assignment stays unused; do not request camera permission and do not scan food barcodes. Honor cgi search pl as paginated JSON search: query, json, page, and page_size mapped onto GET https://www.themealdb.com/api/json/v1/1/search.php with s for the query, and onto GET https://www.themealdb.com/api/json/v1/1/lookup.php with i for a saved meal id. Slice the meals array by page and page_size on device. Never call world.openfoodfacts.org or /cgi/search.pl. Never calories, meal slots, or a food barcode. Set User-Agent Salamander/1.0 (iOS; +https://salamander-pass.pro) on every request. Dedicated JSONDecoder with useDefaultKeys. DTO then domain Recipe; ingredient slots become Bowls and the instruction block becomes numbered Walks. Cache every resolved recipe locally. Empty or failed search falls back to the bundled shelf plus the Cookbook. Settings credits TheMealDB as a tappable source link to https://www.themealdb.com.

### 3.5 Navigation contract

Pass-locked chrome. The open ticket never leaves. There is no TabView. Search, Cookbook, and Settings arrive as sheets; dismissing a sheet returns to the same ticket. Mise bowls and fire walks fuse on Home. Opening a Cookbook item writes a Ticket as Mise only when the pass is not Firing; a second open while Firing is refused. After a ServiceMark the plated Ticket leaves the pass and a new open is allowed. ProcessInfo.processInfo.arguments is read once after onboarding. ReviewScreen today opens Home, log opens Cookbook, goals opens Settings. Extra cover keys may open Search. Those keys are launch arguments, not tabs.

### 3.6 Screen composition contract

Pass-root fused cook (Home holds the ticket; Search, Cookbook and Settings are sheets; Cook is not a pushed scene). Physical screens: Home, Search, Cookbook, Settings. Home is the pass: bowls and numbered walks fuse on one ticket and Walk is the live verb. Search is a sheet that queries TheMealDB and saves a Recipe into the Cookbook. Cookbook is a sheet of saved recipes and ServiceMark history. Settings is a sheet for catalog credit, contact, onboarding replay, and data reset. Cook is not a pushed scene. ReviewScreen is read once after onboarding: today=Home, log=Cookbook, goals=Settings. No Today, Scan, or Goals screens.

Section 5 lists the logical functions that must exist. This section decides how
they are grouped into actual screens. Where the two disagree, this section wins.

A TabView with exactly three tabs is the factory stamp — use two or four-to-five destinations, or a different chrome. `-ReviewScreen today|log|goals` are launch keys, not tabs.

---

## 4. Target file organization

Scheme: **By pass role (Pass, Ticket, Bowl, Walk, FireMark, ServiceMark)**

```
Salamander/
  Pass/PassRoot.swift HomeView.swift SearchView.swift CookbookView.swift SettingsView.swift OnboardingView.swift
Ticket/Ticket.swift TicketPhase.swift PassStore.swift
Bowl/Bowl.swift
Walk/Walk.swift WalkMark.swift
FireMark/FireMark.swift
ServiceMark/ServiceMark.swift
  Assets.xcassets/
```

Adapt the leaf files to the architecture, but the top-level shape is fixed. Do
not create a `Utils/` or `Helpers/` dumping ground.

---

## 5. Screens

Build the screens named in section 3.6. The labels below are logical;
actual type names follow this app's naming convention.

### 5.1 Onboarding
Three to four pages. Explains the product, writes initial settings, sets a
completion flag. Skip still writes sensible defaults. Re-runnable from Settings.

### 5.2 Home
A first-class screen for **Home**. Must render empty, populated and error states.

### 5.3 Search
A first-class screen for **Search**. Must render empty, populated and error states.

### 5.4 Cookbook
A first-class screen for **Cookbook**. Must render empty, populated and error states.

### 5.5 Cook
A first-class screen for **Cook**. Must render empty, populated and error states.

### 5.6 Settings
A first-class screen for **Settings**. Must render empty, populated and error states.

### 5.7 Settings
Holds: re-run onboarding, reset all data (confirmed), and the contact link to
the domain contact-us URL.

### 5.8 Twist screen
See section 12. The twist needs at least one screen of its own plus a surface on the home screen.


---

## 6. Domain model

Minimum entities, named per this app's convention:

- **Recipe** — named per this app's convention.
- **CookbookItem** — named per this app's convention.
- Plus whatever the twist in section 12 requires.


---

## 7. Design system

Direction: **Ink and paper mono**

### 7.1 Palette

| Token | Hex | Use |
| --- | --- | --- |
| `background` | `#1F1415` | Screen background |
| `surface` | `#2B1C1D` | Cards, rows, sheets |
| `ink` | `#F2EDEE` | Primary text and icons |
| `accent` | `#E45864` | Primary action, key figure, progress fill |
| `muted` | `#AC9193` | Secondary text, dividers, disabled |

Define these as named colours in `Assets.xcassets` and reach them through one
typed accessor. Never hard-code a hex string anywhere else.

### 7.2 Typography

Family: **SF Pro**

SF Pro via Font.system as the masthead type move: heavy masthead on the ticket name, pull-quote size on the live Walk text (the only oversized moment besides the pass), body at about 17pt and 60 to 75 characters for bowl names and cookbook rows. Display is Walk and the ticket title, short, one or two lines, never more than four, never above 34pt. Caption is Mise, Firing, and Plated. At most six named steps behind one accessor: display, title, headline, body, caption, micro. Weights and step carry hierarchy. No Font.custom, no fixedSize, never below 12pt. Walk index, Bowl counts, and ServiceMark counts go through NumberFormatter with tabular figures. Dynamic Type. At AX5 the Walk pull quote may drop a step so it never clips; names truncate, numbers win. Day edges use Calendar.current.startOfDay then fold to Int YYYYMMDD.

Define a type scale of at most six steps behind one accessor and use only those
steps. Text stays legible at the largest Dynamic Type size.

### 7.3 Layout

- One base spacing unit (4 or 8 pt); only multiples of it.
- Corner radius and elevation are fixed by section 7.4, not chosen per screen.
- Every interactive element is at least 44x44 pt.

### 7.4 Component contract

Corner radius: **18pt** for cards, sheets and primary surfaces; **12pt** for chips, badges and small controls. Reach both through one accessor. Never a bare literal number, and never zero — a hard edge is not this app's design direction.

Elevation: **hairline+fill** — a 1pt hairline border plus a flat fill tint, reused everywhere a surface sits above another.

Primary control: **soft card** — primary actions live inside a rounded card using the radius below, not a flat row with no fill.

This is arithmetic, not a suggestion: every card, sheet, chip and button in this app uses these two radii and this elevation style. Do not introduce a second radius or a second elevation style.

### 7.5 Custom rendering scope

This app's `ui` axis is **SwiftUI pure · take recipecook**.

If that approach uses anything beyond stock SwiftUI/UIKit controls — `Canvas`, `CALayer`, Metal, SceneKit, SpriteKit, RealityKit, a hand-drawn `UIViewRepresentable`, or any other pixel-level custom rendering — confine it to exactly one hero surface on one screen (the mechanic's home view, or the one screen this axis exists to showcase). Every other screen — every list, every settings screen, every sheet, every secondary surface — is built from stock components: `List`, `Form`, `NavigationStack`, `TabView`, `Button`, `.sheet`, native `Text`/`Image`. A second custom-rendered surface elsewhere in the app is a defect, not a stylistic choice.

If **SwiftUI pure · take recipecook** is already fully native (no custom drawing layer), this section is satisfied automatically — there is nothing to confine.

The `ui` axis value is an implementation choice. It must never appear as a user-visible section title or label.

This assignment restates a catalog technique another app already holds. Write a new composition: new types, new layout, new motion. Do not copy source, file trees, or type names from the holder.

### 7.6 Taste DNA

Aesthetic: **editorial** (Editorial: measure, rules, type hierarchy, almost no boxes.)

Reference system: **editorial** — steal rhythm and restraint, not their colours or logos.

Mood: **ink**.

Home rhythm (`masthead`, airy): Masthead, a column, a pull quote. Boxes are optional.

Ink on paper. Rules, not cards. A pull quote is the only oversized moment besides the mechanic.

Type move: Masthead weight, pull-quote size, body 60-75ch.

Motion (`quiet`): Almost no travel. Cross-fade 180ms ease-out. Numbers tick, they do not fly. Reduce Motion: instant swap.

Voice (`editorial`): Complete sentences, no slang, no hype. Captions are real lines.

Anti-slop from KNOWLEDGE.md applies. Taste never overrides contrast, 44pt hits, VoiceOver labels, or Reduce Motion.

---

## 8. UI and UX quality bar

Every item here is a defect if it is missing. Do not treat this as advice.

**Layout**

- Respect safe areas on every screen. Nothing sits under the notch, the Dynamic
  Island or the home indicator.
- The app is portrait-only on iPhone. Lock it in the Info settings and do not
  write rotation-dependent layout.
- No layout shift when asynchronous data arrives. Reserve the final size up
  front, or use a redacted placeholder of the same dimensions.
- Long product names must truncate gracefully, never push a number off screen.
  Numbers win; names truncate.
- Minimum tap target 44x44 pt for every interactive element, including small
  icon buttons and list accessories.
- Pick one base spacing unit and use only multiples of it. No arbitrary values.

**Keyboard**

- The grams field uses `.decimalPad`, and the decimal separator matches the
  user's locale.
- Content scrolls out from under the keyboard. The focused field is always
  visible.
- Tapping outside the field, or scrolling, dismisses the keyboard.
- Validate on the fly: reject negative and non-numeric input rather than
  crashing the parser later.

**Loading and state**

- Every asynchronous operation has a visible loading state.
- Guard against the spinner flash: if the work finishes in under 150 ms, do not
  show a spinner at all.
- Every list has a designed empty state containing a primary action, not just a
  sentence of text.
- Every error state offers a retry, and states plainly what failed.
- Disable the primary button while its action is in flight so it cannot be
  double-tapped into a double push or a duplicate entry.

**Typography and accessibility**

- All text scales with Dynamic Type. Verify at the largest accessibility size:
  nothing may clip or overlap.
- Every icon-only control has an `accessibilityLabel`. Decorative images are
  marked as decorative so VoiceOver skips them.
- Colour is never the only signal. Pair it with a label, a shape or an icon.
- Honour Reduce Motion: replace movement-heavy transitions with a fade.
- Meet contrast requirements against the palette in section 7. Check the muted
  colour against the background specifically; that is where these palettes fail.

**Formatting**

- Format every number with `NumberFormatter`, never string interpolation. Group
  separators and decimal separators must follow the locale.
- Energy is shown as a whole number of kcal. Macros are shown with at most one
  decimal place.
- Round only at the point of display. Stored values keep full precision.
- Day boundaries use `Calendar.current.startOfDay(for:)` in the user's current
  time zone. Handle the day changing while the app is open, and handle the
  short and long days that daylight saving produces.
- Unknown macro values render as a dash or the word "unknown", never as 0.

**Motion and feedback**

- One haptic on a successful commit (a food logged, a target saved). No haptic
  on navigation.
- Animations are short (0.2 to 0.35 s) and use a single shared easing curve.
- Nothing animates on first appearance of a screen except an intentional entry
  transition.

**Navigation**

- Back always works and never loses entered data without asking.
- A destructive action (delete a log row, reset all data) is confirmed.
- Modal sheets can always be dismissed; there is no dead end.
- Deep state is restorable: relaunching returns the user to a sane screen.


Every item here is a defect if it is missing. Section 7.4 fixed the numbers —
this is where they have to show up on screen.

**Hierarchy and density**

- Every screen has exactly one dominant element (a hero number, a canvas, a
  primary card) that the eye lands on first. A screen where every element has
  equal weight reads as a spreadsheet, not a product.
- Related content is grouped into a card or a section with the elevation
  style from 7.4, not left floating on the bare background.
- Unused flat background is not "minimal" — see the density rule in
  `KNOWLEDGE.md`. If a screen has room left after the mechanic and the
  content, add a secondary surface (a stat strip, a recent-activity card, a
  related-item row), not a `Spacer`.

**Components**

- Every card, sheet, chip, row and button in the app uses the corner radius
  and elevation from section 7.4. No screen introduces its own radius or its
  own shadow value "just for this one card".
- Buttons have a pressed state (`ButtonStyle` with a scale or opacity change
  on `isPressed`) and a disabled state that is visibly different, not just
  non-interactive.
- Chips and badges are pill or rounded-rect shaped per 7.4, never a bare
  `Text` with no background sitting where a control is expected.
- A functional control (add, filter, sort, close, more, share, delete) is an
  SF Symbol inside a properly hit-targeted `Button`. SF Symbols are fine and
  expected here — section 16 only bans them as the app's primary brand
  iconography (app icon, empty-state hero, onboarding art), which is what the
  generated assets in section 13 are for.

**Depth and material**

- At least one surface in the app (a sheet, a modal, a floating toolbar) uses
  the elevation style from 7.4 to visibly sit above the content behind it.
  A flat app with no depth anywhere reads as a wireframe.
- Icons and generated art sit on the surface colour from 7.1, never directly
  on a colour that makes their edges disappear.

**Motion as feedback, not decoration**

- The one dominant element in a screen (7.4's primary control, the mechanic's
  hero) responds visibly to touch: a scale, a colour shift, a haptic — pick
  at least one. A control that looks identical pressed and unpressed reads as
  broken, not calm.

**Taste DNA (section 7.6)**

- Home uses the assigned layout family and density. Three identical equal-weight
  cards, a leftover bento hole, or a second column structure copied down the
  page is a defect.
- Copy follows the assigned voice. No em-dash, no elevate/unlock/seamless, no
  emoji, no SECTION 01 labels.
- Motion follows the assigned personality and honours Reduce Motion with a fade.
  One signature motion per view. No glow stacked on glass stacked on spring.
- Tokens by intent: the live verb wears accent; delete does not wear primary.


---

## 9. Concurrency

The target builds with Swift 6.2 and `SWIFT_STRICT_CONCURRENCY = complete`. It
must compile with **zero concurrency warnings**. Warnings here become crashes
later, so they are not negotiable.

- All UI types are `@MainActor`. Annotate the type, not individual methods.
- Any value crossing an actor boundary is `Sendable`. Prefer immutable structs
  of primitives.
- Do not use `@unchecked Sendable`. If it is genuinely unavoidable, it needs a
  comment explaining what guarantees the safety.
- No mutable global state. No `static var` that is written after launch.
- Networking and storage APIs are `async` and honour cancellation. When the
  search query changes, cancel the in-flight task; do not let a stale response
  overwrite fresh results.
- Use structured concurrency. Avoid `Task.detached` unless there is a stated
  reason. Never fire a `Task` that outlives the view without owning it.
- Never use `DispatchQueue.main.asyncAfter` to paper over an ordering problem.
  Fix the ordering.
- `Timer` and notification observers are invalidated in `deinit` or on
  disappear.


---

## 10. Persistence engineering

Chosen technology: **UserDefaults+Codable**

One Codable PassDocument with schemaVersion from 1, Recipes, Tickets, Bowls, WalkMarks, FireMarks, ServiceMarks, cached catalog rows, and daykeys as Int YYYYMMDD, encoded to JSON Data in UserDefaults under slm.pass.v1. Ticket phase is Mise, Firing, or Plated. Walk index is derived as the WalkMark count and is never stored. Idle sleep is derived from Firing and is never stored. In-memory PassStore is the source of truth. UserDefaults is the projection. Views never touch UserDefaults. Debounce writes. Flush when scenePhase becomes inactive or background, and after every Bowl, Walk, Retract, Save, open, or reset. Decoding failure falls back to slm.pass.v1.backup, then an empty pass, never a crash. resetAllData() is reachable from Settings. Tests use a private UserDefaults suite. Simulator seed only once behind slm.demo.v1 writes several Cookbook recipes from the local shelf, one Ticket already Firing with remaining Walks so Walk is live, at least one ServiceMark so the Cookbook count is not zero, marks onboarding complete, and never seeds an empty pass as the first frame. Never seed on a device. Cached recipes catch empty or failed TheMealDB search.

This app persists to **files on disk**. The following are mandatory.

- Write atomically. Either `Data.write(to:options: .atomic)` or write to a
  temporary file and `FileManager.replaceItemAt`. A non-atomic write that is
  interrupted leaves a truncated file and the app will not launch.
- Create the containing directory with
  `withIntermediateDirectories: true` before the first write.
- Every document carries a `schemaVersion` field from version 1, and the decoder
  switches on it.
- Decoding failure must be recoverable: keep the previous good file as a
  `.backup`, fall back to it, and if that also fails start from empty state and
  tell the user. Never crash on a corrupt file.
- All file IO happens off the main thread. The main thread never blocks on disk.
- Debounce writes during rapid edits, but force a flush when `scenePhase`
  becomes `.inactive` or `.background`, and after any destructive action.
- Exclude caches from backup with `URLResourceValues.isExcludedFromBackup` where
  appropriate; user data belongs in Application Support and should be backed up.
- Keep an explicit in-memory source of truth and treat the file as a projection
  of it, so a failed write never leaves the UI showing data that does not exist.


Regardless of technology:

- One seam between domain logic and storage; the UI never touches storage types.
- Writes survive a force-quit. Do not rely on `applicationWillTerminate`.
- Provide `resetAllData()`, used by tests and reachable from Settings.

---

## 11. Networking

- One client type owns both Open Food Facts endpoints.
- Set `User-Agent` on every request. Open Food Facts throttles clients that do
  not identify themselves.
- 15 second timeout. One retry on a transient transport failure, then a typed
  error. Do not retry a 404.
- Cancel the in-flight search when the query changes. Debounce input by roughly
  300 ms.
- Decode into DTO types that mirror the JSON exactly, then map to domain types.
  Never decode straight into your domain model.
- Dedicated `JSONDecoder` with `.useDefaultKeys`. Never `convertFromSnakeCase` —
  Open Food Facts keys like `energy-kcal_100g` break snake_case conversion.
- Resolve a scanned code with `GET /api/v2/product/<barcode>.json`, not a search.
- Open Food Facts data is user-contributed and frequently incomplete. Every
  numeric field is optional. A product with no energy value is a normal case
  that the UI must present, not an error.
- Some numeric fields arrive as strings. The decoder must accept both a number
  and a numeric string for every nutriment.
- `status` of `0` in the product response means not found. Map it to a distinct
  error case so the UI can offer manual entry.
- Never crash on malformed JSON. A decoding failure is a handled error.
- Cache every resolved product locally on success, so the app degrades to a
  working offline catalogue.


Set `User-Agent: Salamander/1.0 (iOS; +https://salamander-pass.pro)` on every request. Never reuse another app's string.
Use the **cgi search pl** search endpoint for this app.

---

## 11b. App Store readiness

The app must be submittable without further work.

- `PrivacyInfo.xcprivacy` in the target, declaring the UserDefaults access API
  reason `CA92.1` and the file timestamp reason `C617.1`, with
  `NSPrivacyTracking` false and no collected data types.
- `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` in the pbxproj so TestFlight
  does not sit on Missing Compliance.
- `NSCameraUsageDescription` written specifically for this app. Generic strings
  get rejected.
- `LSApplicationCategoryType` of `public.app-category.healthcare-fitness`.
- Portrait only, iPhone and iPad (`TARGETED_DEVICE_FAMILY = "1,2"`).
- No account, no sign-in, no delete-account flow, no in-app purchase, no ads, no
  user-generated content, and therefore no report or block UI.
- App Tracking Transparency is never invoked.
- The camera is the only sensitive permission requested.
- Guideline 5.1.1 (Privacy): do not encourage or direct the user to grant camera
  access. A pre-permission screen may exist, but the proceed button must be
  **Continue** or **Next** — never "Allow camera", "Enable camera",
  "Grant camera", or a bare Allow/Enable that calls `requestAccess`. The
  system dialog is the only Allow. Denied/restricted offers Open Settings.
- The app must not present itself as a clinician or as medical advice.
- Guideline 4.2 (Design — Minimum Functionality): the binary must be a native
  product, not a web browsing experience. No WKWebView / SFSafariViewController
  / UIWebView as home, a tab, or the primary UX. A content catalog, article
  reader, or site wrapper that could be a website is a reject. Push
  notifications, Core Location, and sharing do not make that acceptable.
- Guideline 1.4.1 (Safety — Physical Harm): if the binary shows health or
  medical recommendations, body-based targets, dosages, "you should" guidance,
  or product health claims (food, drink, supplement, remedy), put citations
  in the app. Tappable links to the sources, easy to find: same screen as the
  claim, or a Sources row one tap from Settings. Name the source (Open Food
  Facts, USDA FoodData Central, WHO, NIH MedlinePlus, …) and link it. A
  "not medical advice" footer without sources is a reject. A personal log
  that never advises does not invent claims to cite.
- Nutrition catalog data is credited to the database this app actually uses
  (Open Food Facts unless the spec names another). Credit is a tappable link,
  not a dead "OpenFoodFacts" label.


Ignore the food-log and Open Food Facts lines above when they conflict with this
family. Category for this app is `public.app-category.food-and-drink`. Camera permission only if the
product actually captures.

Project settings that follow from the above:

```yaml
INFOPLIST_KEY_UIUserInterfaceStyle: Dark
INFOPLIST_KEY_UISupportedInterfaceOrientations: UIInterfaceOrientationPortrait
INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad: UIInterfaceOrientationPortrait
INFOPLIST_KEY_UIRequiresFullScreen: YES
INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO
INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.food-and-drink
TARGETED_DEVICE_FAMILY: "1,2"
SWIFT_STRICT_CONCURRENCY: complete
```

---

## 12. Functional twist: Mise-then-fire (last Bowl writes FireMark and flips Mise to Firing; Walks file the fire; last Walk writes ServiceMark and freezes; idle sleep is held only while Firing)

Home is tonight's ticket on the pass. Search saves a Recipe into the Cookbook, and opening a book item writes a Ticket as Mise. Mise-then-fire means bowls file first; the last Bowl writes a FireMark, flips Mise to Firing, and holds idle sleep. Walks file the fire; the last Walk writes a ServiceMark, flips Firing to Plated, and restores sleep. Retract peels the last Bowl or WalkMark. Seed writes one Ticket already Firing so the next Walk is live, and the Cookbook counts ServiceMarks.

This is the app's marketed differentiator. It must be:

- visible on the home screen, not buried in settings;
- backed by real persisted data, not a cosmetic flourish;
- covered by at least one unit test;
- described in the README as the reason a user would pick this app.

---

## 13. AI-generated assets

Art style: **3D glass render glassmorphism · take recipecook**


This assignment restates a catalog technique another app already holds. Write a new composition: new types, new layout, new motion. Do not copy source, file trees, or type names from the holder.

Base prompt, reused and extended for every asset:

```
3D studio glass render with glassmorphism: frosted depth, soft diffused studio light, editorial still life, ink on paper atmosphere, quiet masthead composition. Solid kitchen-pass objects with glazed or enameled surfaces. Not a hollow glass box, not a wire frame, not a transparent vitrine, no text, no words, no emoji.
```

All 12 images below are required. Generate each one, export
as PNG, and add it to `Assets.xcassets` as its own image set named exactly as
given. Every name carries the `slm_` prefix.

### 13.1 App icon rules (strict)

The icon is rejected by App Store Connect if any of these are wrong:

- Exactly **1024 x 1024 px**.
- **No alpha channel.**
- sRGB colour profile, 8 bits per channel, PNG.
- **No text and no words** in the artwork.
- **No rounded corners and no built-in mask.**
- The subject stays inside the middle 80%.

### 13.2 Full asset list

| # | Image set | Size (px) | Alpha | Purpose |
| --- | --- | --- | --- | --- |
| 1 | `slm_AppIcon` | 1024x1024 | **NO** | App Store icon. NO alpha channel, NO transparency, NO text, NO rounded corners, NO drop shadow outside the canvas. |
| 2 | `slm_Splash` | 1290x2796 | fill | Launch background. The middle third must stay quiet so the wordmark reads on top. |
| 3 | `slm_Onboarding1` | 1024x1536 | **required cutout** | Onboarding page 1 illustration: what the app is for. |
| 4 | `slm_Onboarding2` | 1024x1536 | **required cutout** | Onboarding page 2 illustration: the main verb. |
| 5 | `slm_Onboarding3` | 1024x1536 | **required cutout** | Onboarding page 3 illustration: why they stay. |
| 6 | `slm_EmptyHome` | 1024x1024 | **required cutout** | Empty state: the home screen has nothing yet. Calm and inviting, never sad. |
| 7 | `slm_EmptyList` | 1024x1024 | **required cutout** | Empty state: a secondary list has no rows. |
| 8 | `slm_CardBackdrop` | 1200x800 | fill | Backdrop art for a primary card. Low contrast so text stays readable. |
| 9 | `slm_ControlFace` | 512x512 | **required cutout** | Custom control artwork used for the primary interactive element. |
| 10 | `slm_TwistHero` | 1024x1024 | **required cutout** | Hero art for the 'Mise-then-fire (last Bowl writes FireMark and flips Mise to Firing; Walks file the fire; last Walk writes ServiceMark and freezes; idle sleep is held only while Firing)' feature screen. |
| 11 | `slm_SuccessMark` | 512x512 | **required cutout** | Shown briefly when the primary action succeeds. |
| 12 | `slm_HeaderDecor` | 1200x600 | **required cutout** | Decorative header accent on the main screen. |

### Prompt per asset

**`slm_AppIcon`** — 1024x1024

```
3D glass-render emblem of a solid iron salamander broiler plate filling the canvas edge to edge, frosted studio light, no text, no words, no letters, no alpha, no rounded corners, no drop shadow outside the canvas.
```

**`slm_Splash`** — 1290x2796

```
Tall editorial pass scene, quiet uncluttered centre band, paper ticket and solid iron broiler suggested in frosted 3D glass light, no text, no words.
```

**`slm_Onboarding1`** — 1024x1536

```
Solid copper mise bowl and a paper kitchen ticket on a pass, isolated opaque subjects, frosted studio light, no hollow glass, no text.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`slm_Onboarding2`** — 1024x1536

```
A hand mid-tap on a numbered paper walk slip on a kitchen pass, solid opaque subjects, frosted studio light, no text.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`slm_Onboarding3`** — 1024x1536

```
A finished plated dish on a pass next to a closed ticket spike, solid opaque subjects, frosted studio light, no text.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`slm_EmptyHome`** — 1024x1024

```
A solid closed ceramic mise bowl waiting on a pass, fully opaque clay, not glass, not a wire frame, isolated on transparent ground, no text.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`slm_EmptyList`** — 1024x1024

```
A solid closed cloth-bound cookbook lying shut on a wooden shelf, fully opaque, not a hollow box, isolated on transparent ground, no text.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`slm_CardBackdrop`** — 1200x800

```
Abstract ink-on-paper wash with frosted glass depth filling the canvas, low contrast, no text, no recognizable object, no letters.
```

**`slm_ControlFace`** — 512x512

```
Solid brass ticket spike face, the Walk control, fully opaque metal, frosted studio light, isolated on transparent ground, no text.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`slm_TwistHero`** — 1024x1024

```
Solid iron salamander broiler finishing a plate, the mise-then-fire emblem, fully opaque, frosted studio light, isolated on transparent ground, no text.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`slm_SuccessMark`** — 512x512

```
Solid service bell on a pass, plated confirmation, fully opaque metal, frosted studio light, isolated on transparent ground, no text.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`slm_HeaderDecor`** — 1200x600

```
Solid paper masthead ornament, a wide ink rule with a small salamander iron, fully opaque, isolated on transparent ground, no text.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```


### 13.3 Asset rules

- Cut-outs (everything except AppIcon, Splash, CardBackdrop): isolated subject,
  real PNG alpha, all four corners transparent. No square plate.
- Assets must be semantically different from each other.
- Record the exact prompt used for every asset in the README.
- SF Symbols are permitted only for close, chevron, share and similar system
  affordances.

Scanner frames, reticles, and seamless tiles are drawn in SwiftUI via `Path` or `Shape`. GenerateImage is not used for those. Every other in-app graphic (except AppIcon, Splash, CardBackdrop) is a **cutout**: isolated SOLID opaque subject in the center, real PNG alpha, all four corners transparent. An opaque square plate inside a circle or pentagon is a fail. A hollow glass box or wire frame with a transparent center is a fail.

---

## 14. Demo data

Seed a small local demo dataset for this family's entities so Simulator
screenshots are not empty. The same seed must mark onboarding complete and
fill the primary surface — otherwise `-ReviewScreen` never fires. Never seed
on a physical device. Guard with `#if targetEnvironment(simulator)` and
`slm.demo.v1`.

Seed the happy path: the home primary verb is enabled. The blocked / gated /
error state is a unit-test fixture, not Simulator home. Home chrome names the
job and the next tap in words a stranger knows. Axis values (`ui`, `naming`,
`architecture`) never become user-visible titles. A card that looks tappable
is a `Button`. A readout does not use button chrome.

---

## 16. Anti-patterns

The following will fail review:

- `try!`, `as!`, or force-unwrapping anything derived from the network, the
  database or a file.
- `fatalError` anywhere reachable at runtime. It is acceptable only for a
  programmer error in an initialiser that cannot fail in practice, and needs a
  comment.
- Swallowing an error with an empty `catch`.
- `print` used as production logging.
- A hard-coded hex colour outside the single colour accessor.
- A hard-coded font name outside the single typography accessor.
- An SF Symbol used as the app's brand iconography — the app icon, the
  empty-state hero, or onboarding art. Those come from section 13. SF Symbols
  are the right choice for every functional control (add, filter, sort,
  close, share, delete) — leaving those as bare text instead of a symbol is
  also a defect.
- Storing a value that can be computed (day totals, remaining budget, macro
  percentages).
- Blocking the main thread on disk or network work.
- `UIScreen.main` for sizing. Use the geometry the layout system gives you.
- Index positions used as list identity. Identity is a stable identifier.
- A view that reaches into the persistence layer directly, bypassing the
  architecture's designated seam.
- Business logic inside a `View` body or a `UIViewController` method, when the
  assigned architecture places it elsewhere.
- Copying a source file from another app in this batch.
- A `TabView` with exactly three tabs. That is the factory stamp — two or
  four-to-five destinations, or a different chrome. ReviewScreen keys are
  not tabs.


---

## 17. Tests

Add a unit test target `SalamanderTests` covering at minimum:

1. The core domain invariant of this family (the thing that would be wrong if
   the calculator, decay, crate, or log lied).
2. Empty, populated and invalid input paths for the primary verb.
3. The section 12 twist logic.
4. One architecture-specific test proving the pattern holds.
5. A persistence round-trip: write, relaunch-equivalent reload, verify.
6. Parse `ProcessInfo.processInfo.arguments` once after onboarding. 
   `-ReviewScreen today|log|goals` switches the running app's live navigation. Extra cover slugs open those screens.
   Cover that parser with a unit test. Do not host a `View` in the test.

---

## 18. README.md

Write `README.md` at the app folder root covering:

1. What the app does and who it is for.
2. The architecture used and **why** it suits this product.
3. The unique feature added and how it works.
4. The AI art style and the exact prompt used for every asset.
5. How this app differs from others in the batch.
6. Build instructions.

---

## 19. Definition of done

**Build**
- [ ] `xcodegen generate` succeeds.
- [ ] `xcodebuild -scheme Salamander -destination 'generic/platform=iOS' build` succeeds.
- [ ] Zero new compiler warnings.
- [ ] Strict concurrency `complete` compiles clean.
- [ ] Test target passes.

**Function**
- [ ] Onboarding to first successful primary action works on a clean install.
- [ ] Every screen in section 3.6 exists and handles empty / filled / error.
- [ ] Reset and contact link live in Settings.
- [ ] Force-quitting immediately after a write loses nothing.
- [ ] Seeded home names the job and next tap; primary verb enabled.
- [ ] App reads `-ReviewScreen today|log|goals` after onboarding.

**Uniqueness**
- [ ] Architecture matches **Ticket ADT fold (Mise | Firing | Plated); the pass is a fold over Tickets; last Bowl writes a FireMark and holds idle; last Walk writes a ServiceMark and restores sleep; Walk index is the WalkMark count** with no leakage across layers.
- [ ] UI approach matches **SwiftUI pure · take recipecook**.
- [ ] Custom rendering, if any, is confined to one hero surface (section 7.5).
- [ ] Navigation matches **Pass-locked chrome (the open ticket never leaves; Search, Cookbook and Settings arrive as sheets; mise and fire fuse on Home)**.
- [ ] Screen composition follows section 3.6.
- [ ] Typography uses **SF Pro** and nothing else.
- [ ] Palette matches section 7.1 exactly.
- [ ] Home rhythm and motion match section 7.6. No second look.

**Quality**
- [ ] Section 8 UI/UX bar satisfied end to end.
- [ ] Contact link present.
- [ ] `PrivacyInfo.xcprivacy` present and correct.
- [ ] README complete.

---

## 20. Build commands

```bash
cd Salamander
xcodegen generate
xcodebuild -scheme Salamander -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
xcrun simctl list devices available
xcodebuild -scheme Salamander -destination 'platform=iOS Simulator,id=<UDID>' test
```

Signing is off only on that command line. Do not put CODE_SIGNING_ALLOWED, CODE_SIGNING_REQUIRED, CODE_SIGN_IDENTITY or DEVELOPMENT_TEAM in project.yml — CI signs the archive. Leave CODE_SIGN_STYLE: Automatic as the scaffold set it. The exact simulator does not matter — use any available UDID from the list.
