# Salamander

Tap numbered cook steps on tonight's ticket.

Salamander is for home cooks who need mise bowls and fire walks awake on the counter. It is not a recipe blog, not a shop, and not a calorie log.

## Architecture

A **Ticket** is an algebraic data type with phases **Mise**, **Firing**, and **Plated**. The pass is a fold over Tickets: at most one ticket is open, and plated tickets remain as **ServiceMark** history.

- Opening a cookbook recipe writes a Ticket as Mise.
- Filing a **Bowl** checks that mise line. The last unfiled bowl writes a **FireMark**, folds Mise to Firing, and holds idle sleep so the screen stays awake.
- Tapping **Walk** writes a **WalkMark**. The walk index is the WalkMark count. It is never stored as a cursor.
- The last walk writes a **ServiceMark**, folds Firing to Plated, and restores sleep.
- **Retract** peels the last Bowl or WalkMark and reverses the mark that write caused. A second open while Firing is refused.

This pattern fits the product because the job is tonight's ticket, not a feed of recipes. `PassStore` owns the fold. Views call `fileBowl`, `fileWalk`, `retract`, `saveRecipe`, and `openFromCookbook` and never touch UserDefaults. Idle sleep is derived from Firing.

Pass-locked chrome keeps the open ticket on screen. Search, Cookbook, and Settings arrive as sheets. Mise bowls and fire walks fuse on Home. Cook is not a pushed scene.

## Mise then fire

Home is tonight's ticket. Search saves a recipe into the cookbook. Opening a book item writes Mise. Bowls file first. The last bowl lights the iron and holds idle sleep. Walks file the fire. The last walk plates the dish and sleep returns. Simulator seed writes one ticket already Firing so Walk is live, and the cookbook counts ServiceMarks.

That is why a cook would pick this app: the pass stays awake only while the iron is live, and the next tap is always the next fire line.

## Look

Ink and paper mono on SF Pro. Masthead, a column, a pull quote. Cards and sheets use 18pt corners. Chips use 12pt. Elevation is a 1pt hairline plus a flat fill. Tokens live in `PassInk`, `PassType`, `PassSpace`, and `PassRadius`. Palette: background `#1F1415`, surface `#2B1C1D`, ink `#F2EDEE`, accent `#E45864`, muted `#AC9193`.

Art style: 3D studio glass render with glassmorphism: frosted depth, soft diffused studio light, editorial still life, ink on paper atmosphere, quiet masthead composition. Solid kitchen-pass objects with glazed or enameled surfaces. Not a hollow glass box, not a wire frame, not a transparent vitrine, no text, no words, no emoji.

### Asset prompts

**slm_AppIcon** — 3D glass-render emblem of a solid iron salamander broiler plate filling the canvas edge to edge, frosted studio light, no text, no words, no letters, no alpha, no rounded corners, no drop shadow outside the canvas.

**slm_Splash** — Tall editorial pass scene, quiet uncluttered centre band, paper ticket and solid iron broiler suggested in frosted 3D glass light, no text, no words.

**slm_Onboarding1** — Solid copper mise bowl and a paper kitchen ticket on a pass, isolated opaque subjects, frosted studio light, no hollow glass, no text.

**slm_Onboarding2** — A hand mid-tap on a numbered paper walk slip on a kitchen pass, solid opaque subjects, frosted studio light, no text.

**slm_Onboarding3** — A finished plated dish on a pass next to a closed ticket spike, solid opaque subjects, frosted studio light, no text.

**slm_EmptyHome** — A solid closed ceramic mise bowl waiting on a pass, fully opaque clay, not glass, not a wire frame, isolated on transparent ground, no text.

**slm_EmptyList** — A solid closed cloth-bound cookbook lying shut on a wooden shelf, fully opaque, not a hollow box, isolated on transparent ground, no text.

**slm_CardBackdrop** — Abstract ink-on-paper wash with frosted glass depth filling the canvas, low contrast, no text, no recognizable object, no letters.

**slm_ControlFace** — Solid brass ticket spike face, the Walk control, fully opaque metal, frosted studio light, isolated on transparent ground, no text.

**slm_TwistHero** — Solid iron salamander broiler finishing a plate, the mise-then-fire emblem, fully opaque, frosted studio light, isolated on transparent ground, no text.

**slm_SuccessMark** — Solid service bell on a pass, plated confirmation, fully opaque metal, frosted studio light, isolated on transparent ground, no text.

**slm_HeaderDecor** — Solid paper masthead ornament, a wide ink rule with a small salamander iron, fully opaque, isolated on transparent ground, no text.

## Why it is not a clone

This is the first recipe_cook in the portfolio. Home is walk-the-fire on one Ticket, not Speedwell's pour from seated bottles, not Deadwax crate-and-rate, not KcalCraft's per-100g builder, and not a food tracker with slots or macros. Cook mode is the persisted verb: Mise then Firing then Plated, with idle held only while Firing. TheMealDB search is input. The native ticket is the product.

## Build

```bash
cd Salamander
xcodegen generate
xcodebuild -scheme Salamander -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```
