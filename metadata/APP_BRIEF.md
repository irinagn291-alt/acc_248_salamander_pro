<!-- gf-brief source=b1c665e40e6ae1ead8b908cd86050962f489b1a0dfbfd2bed3c15713a1d87540 written=2026-09-26T01:27:51+03:00 -->
# Salamander

## What it is
Salamander is a kitchen-pass app for cooks who work one dish at a time. You open a recipe onto tonight’s ticket, file mise bowls, then walk numbered fire lines until the dish plates. It is for people who want a counter-style cooking flow, not a recipe blog.

## Launch and onboarding
1. Cold launch shows a full-bleed splash image with no text or buttons. The system may also show the standard notification permission dialog at this time (no custom pre-prompt in the app).
2. If the pass cannot open: headline `"The pass did not open."`, body `"The pass folder could not be opened."`, button `"Try again"`.
3. First launch (and after reset, or when replaying from Settings) shows four dark onboarding pages with page dots. Each page has a headline, body, a primary button, and `"Skip"`.
   - Page 1 — `"Tonight's ticket"` / `"Numbered fire walks stay on the counter. This is a kitchen pass, not a recipe blog."` / `"Next"`
   - Page 2 — `"Walk the fire"` / `"Tap the next walk on the open ticket. Retract peels a tap that was wrong."` / `"Next"`
   - Page 3 — `"Plate the dish"` / `"The last walk writes a service mark. The ticket leaves the pass and sleep returns."` / `"Next"`
   - Page 4 — `"Mise, then fire"` / `"Bowls file first. The last bowl lights the iron and holds idle sleep until the last walk."` / `"Continue"`
4. `"Skip"` or finishing page 4 lands on Home.

## Screens

### Home (tonight’s ticket)
Home is always on screen. There is no tab bar. Bottom chrome:
- Magnifying glass — accessibility `"Search the catalog"` — opens Search.
- `"Cookbook"` — opens Cookbook.
- `"Fire rule"` — opens the `"Mise then fire"` sheet.
- Gear — accessibility `"Open settings"` — opens Settings.
- Counter text `"{n} plated"` (locale-formatted number).

**Empty pass (never cooked)**  
Masthead `"Tonight's ticket"` and `"Open a cookbook recipe so mise bowls and fire walks can share this pass."`  
Empty plate: `"The pass is waiting."` / `"Open a saved recipe onto tonight's ticket. Mise bowls file first. Then the walks stay awake."` / `"Open cookbook"`.

**Empty pass after plating**  
Masthead `"The pass is clear."` plus the plated line `"The dish is plated. Service is marked. Sleep is restored."`  
Empty plate: `"Service is marked."` with that plated line / `"Open another recipe"`.

**Open ticket masthead**  
Dish name; phase `"Mise"`, `"Firing"`, or `"Plated"`; job line:
- Mise: `"File every mise bowl. The last bowl writes a fire mark and the walks wake."`
- Firing: `"Tap Walk to file this fire line. The screen stays awake until the last walk."`
- Plated: `"This ticket has left the pass."`

Fault banner on Home shows the fault text and `"Dismiss"`.

### Cook surface (on Home when a ticket is open)
**Refused tap:** `"That tap was refused."` + fault body + `"Back to the ticket"`.  
**Broken recipe:** `"This ticket has no fire."` / `"The recipe is missing bowls or walks. Open another cookbook item."` / `"Open cookbook"`.  
**Plated remnant:** `"This ticket has plated."`

**Idle strip**  
- Held: `"Idle sleep is held. The last bowl wrote a fire mark."`  
- Waiting: `"Idle sleep waits. File the last bowl to light the iron."`  
- Chip `"Mise then fire"` opens the rule sheet.

**Mise**  
- Heading `"Mise bowls. {n} still open."`  
- `"Next bowl"` with bowl name (or `"Every bowl is filed."`) and measure.  
- `"File bowl"` files the next bowl.  
- `"Fire walks wait."` / `"They stay quiet until the last bowl files."` plus numbered muted walk lines.  
- Bowl rows: `"Filed"` or `"Waiting"`; waiting rows show `"File this bowl."` / `"File"` for the live bowl, or measure / `"Next"` for others.  
- `"Retract"` peels the last bowl or walk mark when allowed.

**Firing**  
- Heading `"Mise is closed. {n} bowls filed."` (or `"Mise is closed."` if plated).  
- Caption `"Walk {current} of {total}."` and the live walk text (or `"The fire is quiet."`).  
- `"Walk"` / `"File this fire line."` files the live fire line.  
- Remaining: `"Every fire line is filed."` / `"One fire line remains after this tap."` / `"{n} fire lines remain, counting this one."`  
- On wider layouts, other walks list as `"Filed"` or `"Waiting"`.  
- `"Retract"`.

Loading accessibility labels while busy: `"Filing the walk"`, `"Filing the bowl"`, `"Retracting"`.

### Search (sheet)
Title `"Search"`. Trailing close control (accessibility `"Close"`).  
Field placeholder `"Dish name"`.  
Empty query: `"Name a dish."` / `"Search maps onto TheMealDB. An empty catalog falls back to the local shelf."` / `"Open cookbook"`.  
No matches: `"No dishes matched."` / `"Try another name, or open the cookbook shelf."` (or a fault line) / `"Try again"`.  
Catalog fallback notice: `"The catalog did not answer. These dishes are already on the shelf."`  
Result meta: `"{area}, {n} bowls, {n} walks"` (area omitted if empty).  
Row button `"Save"` adds the dish to the cookbook. Save failure: `"The pass could not be saved. Try again."`

### Cookbook (sheet)
Title `"Cookbook"`. Close control (accessibility `"Close"`).  
Empty: `"The cookbook is empty."` / `"Search the catalog and save a dish. Opening a saved recipe writes tonight's ticket as mise."` / `"Search the catalog"`.  
Open-fault empty: `"The cookbook could not open that recipe."` + fault + `"Dismiss"`.  
Header: `"Saved recipes."` / `"{n} saved. The book counts {n} service marks."`  
When a ticket is already open: `"Tonight's ticket is still firing. Plate it before opening another recipe."`  
Rows: name; `"Saved {medium date}. {n} bowls, {n} walks."`; trailing `"Open"` or `"Busy"`. Tapping `"Open"` writes tonight’s ticket as mise and returns to Home.  
Section `"Service marks"`: empty `"No dishes have plated yet."`, or plated dish names with medium dates.

### Mise then fire (sheet)
Title `"Mise then fire"`. Close control (accessibility `"Close"`).  
Empty (no ticket, no fire marks): `"Mise, then fire."` / `"Bowls file first. The last bowl writes a fire mark, flips the ticket to firing, and holds idle sleep. Walks file the fire. The last walk writes a service mark and sleep returns."` / `"Open cookbook"`.  
Fault: `"The iron refused that tap."` + fault + `"Back to the ticket"`.  
Populated: state headline; `"Bowls close mise. Walks close the fire. Idle sleep is a derived hold, never a stored switch."`; figures `"Fire marks"`, `"Walk marks on the open ticket"`, `"Service marks"`; idle line `"The screen will not sleep while this ticket is firing."` or `"The screen may sleep. Idle is held only while a ticket is firing."`; `"Back to the ticket"`.  
Headlines by state: `"The last service mark is on the spike."` / `"Mise is open. File bowls until the iron takes the ticket."` / `"The iron is live. Walk the fire until service."` / `"This ticket has plated."`

### Settings (sheet)
Title `"Settings"`. Close control (accessibility `"Close"`).  

**Empty device:** `"This device holds no tickets."` / `"Replay the pass notes or search the catalog. Reset stays available after you cook."` / `"Search the catalog"`, plus the action buttons below.

**Pass notes (when there is data):** heading `"Pass notes"`; status `"{n} recipes on the shelf. {n} service marks. {n} fire marks. {n} walk marks."`; optional fault with `"Try again"`.

**Actions**
- `"Replay the pass notes"` — shows onboarding again.
- `"TheMealDB catalog"` — opens the catalog site in Safari (URL not printed on screen).
- Credit: `"Search dishes come from TheMealDB. That catalog is the source for names, bowls, and walks."`
- `"Contact the pass"` with on-screen URL `"https://salamander-pass.pro/contact-us"` — opens that page.
- `"Reset all data"` → confirmation title `"Reset the pass"`, message `"This removes tonight's ticket, the cookbook, and service marks on this device."`, buttons `"Reset all data"` and `"Cancel"`. After reset, onboarding shows again.

**Marks ledger:** `"Marks on this pass"` with rows `"Recipes on the shelf"`, `"Fire marks"`, `"Walk marks"`, `"Service marks"`; `"Cookbook shelf"` (empty `"The shelf has no saved recipes."` or names with dates); `"Plated dishes"` (empty `"No dishes have plated yet."` or names with dates).

## Features
- Kitchen-pass flow for one open ticket at a time
- Onboarding that can be skipped or replayed
- Search dishes by name (TheMealDB, with local shelf fallback)
- Save dishes into a Cookbook
- Open a saved recipe onto tonight’s ticket as mise
- File mise bowls, then Walk numbered fire lines
- Retract the last bowl or walk mark
- Fire rule / `"Mise then fire"` explanation and mark counts
- Idle sleep held while a ticket is firing (screen stays awake)
- Service marks and plated history
- Settings ledger of shelf and marks
- Contact the pass via the support URL
- Reset all data on this device

## Behaviours that can look like bugs
- Cookbook rows show `"Busy"` and will not open while any ticket is already open (mise or firing). Banner/fault: `"Tonight's ticket is still firing. Plate it before opening another recipe."` Plate the current dish (file every bowl, then Walk every fire line) before opening another.
- `"Walk"` stays dimmed until the ticket is firing and walks remain; file every mise bowl first. Fault if early: `"File every mise bowl before the first walk."` / `"Walks file only while the ticket is firing."`
- `"Retract"` stays dimmed when nothing is filed; fault `"There is nothing to retract."`
- `"File bowl"` / `"Walk"` / `"Retract"` / `"Save"` dim while an action is in progress (spinners with `"Filing the bowl"`, `"Filing the walk"`, `"Retracting"`).
- Search with an empty field shows `"Name a dish."` until you type a name.
- Empty Cookbook until you `"Save"` from Search; empty Home until you `"Open"` a cookbook recipe.
- After plating, Home shows `"Service is marked."` / `"The dish is plated. Service is marked. Sleep is restored."` — intentional clear pass, not a crash; use `"Open another recipe"`.
- Search may show `"The catalog did not answer. These dishes are already on the shelf."` and local shelf dishes — intentional fallback.
- Onboarding can reappear after `"Replay the pass notes"` or `"Reset all data"` — intentional.
- Fault screens (`"That tap was refused."`, `"The iron refused that tap."`) need `"Back to the ticket"` or `"Dismiss"` to continue.

## Starter content and resume
Local shelf dishes (search fallback / empty-catalog fallback): `"Salt crust sea bass"`, `"Charred lemon chicken"`, `"Butter mushrooms"`, `"Pass tomato salad"`, `"Iron pork chop"`, `"Herb oil beans"` — each with bowls, measures, and four fire-walk sentences.  
On a normal device install the Cookbook starts empty until you save. (Simulator-only demo may pre-save dishes and leave a live firing ticket; App Store / device builds do not.)  
Unfinished tickets resume: an open mise or firing ticket returns on relaunch until it plates or you reset.

## Permissions
- Notifications: system permission dialog at cold launch; no custom in-app pre-prompt; no usage-description string in Info for notifications.
- Camera: not requested or used in the UI. Info includes usage description `"This app does not use the camera."`

## Absent
Login or accounts; in-app purchase; ads; analytics consent or dashboards; social user-generated content (posts, comments, photos); account deletion flow; App Tracking Transparency prompt.

## Data and support
Tonight’s ticket, cookbook saves, and service marks stay on this device (reset copy: `"…on this device."`; empty Settings: `"This device holds no tickets."`). Search may fetch dish names from TheMealDB when available; otherwise the local shelf is shown.  
Support control: `"Contact the pass"` with `"https://salamander-pass.pro/contact-us"`.

## Scanning and health
None. No barcode or QR scanning. No health, medical, nutrition, or calorie information.

## Platform
English UI only (no localization files); dates and numbers follow the device locale. No region lock. Portrait only on iPhone and iPad. Full-screen (no Split View / Slide Over). Forced dark appearance. Minimum iOS 17.0.

## Category
Food & Drink
