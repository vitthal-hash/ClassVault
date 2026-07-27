# Academic Assistant

Flutter app for organizing lectures, resources, and AI-powered study help,
built one phase at a time per the project plan.

## Current status: Phase 16 — Settings ✅ (Phases 1–15 also done — all 16 phases complete)

Phase 16 — what's new, covering the plan's full list exactly:
- **Theme**: new `AppSettings` Isar model (singleton row) with a
  `themePreference` field (System/Light/Dark), plus `SettingsProvider`
  so `MaterialApp.themeMode` reacts live the moment it's changed in
  Settings — no restart needed
- **OCR Language**: also on `AppSettings`, as an `OcrScript` rather
  than a language list — ML Kit's on-device recognizer works by
  *script* (Latin, Chinese, Devanagari, Japanese, Korean), and one
  script covers every language written in it, so the picker only
  offers choices ML Kit can actually honor. `TextExtractionService`
  now rebuilds its recognizer whenever this changes, still only doing
  so when the script actually differs from last time
- **Export Database** / **Import Database**: Export copies the live
  Isar file via Isar's own `copyToFile` (safe to call while the
  database is open) and hands it to the OS share sheet — Drive, Files,
  email, another device, wherever. Import lets you pick a previously
  exported file and replaces the current database with it; since Isar
  can't hot-swap the file under an already-open instance, the app
  closes its connection first and tells you to fully close and reopen
  the app afterward rather than pretending a seamless in-place reload
  is possible
- **Backup Folder** / **Clear Cache**: Backup Folder uses the OS
  folder picker (already in the app since Phase 3's file picker) and
  saves the choice; "Back Up Now" copies every subject's actual files
  *and* a fresh database snapshot into a timestamped folder there — a
  full, human-browsable backup, not just the database. Clear Cache
  only ever touches the OS-designated temporary directory, never the
  documents folder every subject's files live in, so it can't
  accidentally delete anything real
- New `SettingsService` (the non-sensitive settings row) alongside the
  existing `ApiKeyService` (secure storage, Phase 10) — the Gemini key
  stays the one deliberately-not-plaintext exception; everything else
  here is exactly the kind of setting the plan means by "everything
  readable if you browse the files"
- New `BackupService` for all four backup/restore/cache operations

### Action needed before this run (Phase 16)

New Isar model (`AppSettings`), so **`build_runner` needs to run**
again:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

**No new packages** — `file_picker`, `path_provider`, and `share_plus`
were already in the project from earlier phases and cover everything
Export/Import/Backup/Clear Cache need. No new permissions either.

### This is the last phase — the MVP checklist

Every box in the plan's own MVP checklist is now real: create a
semester; upload a timetable and auto-generate subjects with
Theory/Lab/Tutorial; upload lecture photos with smart subject
suggestions; a clean local folder structure holding every PDF, PPT,
DOCX, and image; OCR'd and editable lecture text; Explain/Summarize/
Key Points/Important Questions/Generate Notes per lecture; a
subject-scoped AI chat grounded in that subject's own material; search
across everything by content, not filename; assignments and syllabus
management; starred lectures with combined revision notes; and fully
offline operation except for the Gemini calls the plan always expected
to need a network for.

### Phase 15 recap

Phase 15 — what's new:
- `Lecture` gained an `isStarred` field — starring IS the Revision
  folder's contents, no separate table needed (same pattern as
  `Subject.isPinned` for Home). Toggle it from a new star icon in the
  Lecture Detail app bar; starred lectures also show a star badge on
  their thumbnail in the Lectures tab grid
- New **Revision** screen: every starred lecture across the active
  semester, grouped by subject, reachable from a new "Revision" card
  on Home (there's no dedicated bottom-nav slot for it, so Home is
  where a cross-subject feature like this naturally lives)
- New `RevisionService` gathers the starred list, and — going ahead
  with the plan's "Later: Generate Revision Notes" now rather than
  deferring it — combines the OCR text of however many lectures you
  select (checkboxes, can span multiple subjects) into one Gemini
  prompt and returns organized notes grouped by topic rather than by
  lecture, with Copy/Share same as Phase 10's per-lecture AI results

### Why notes-generation now instead of "later"

It's the same Gemini call Phase 10 already built (`generateRaw`), just
fed several lectures' text at once instead of one — there was no real
extra complexity to defer, and having it land in the same phase as the
"star" feature it depends on means Revision is a complete, usable
feature the moment this phase lands rather than half-built until some
future phase reopens this same code.

### Action needed before this run (Phase 15)

New field on an existing Isar model (`Lecture.isStarred`), so
**`build_runner` needs to run** again:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

No new packages, no new permissions.

### Phase 14 recap

Phase 14 — what's new:
- New `Assignment` model — title, uploaded PDF path, deadline, and a
  Pending/Submitted `AssignmentStatus`. "Overdue" is never stored: it's
  a derived `isOverdue` getter (pending + past deadline), so marking
  something Submitted late clears the overdue flag immediately with no
  separate cleanup step
- New `AssignmentService` — uploads the PDF into
  `Subject/Assignments/` via the same `FileStorageService` every other
  upload flow already uses, then creates the Isar row
- **Assignments tab is now real** (was a placeholder through Phase 13):
  a "New Assignment" sheet (pick PDF, title, deadline), a list sorted
  soonest-deadline-first, and a tappable status chip that toggles
  Pending ↔ Submitted right from the list — no extra screen needed for
  something this simple, matching the plan's own "Simple." note for
  this phase

### Action needed before this run (Phase 14)

New Isar model (`Assignment`), so **`build_runner` needs to run** again:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

No new packages, no new permissions.

### Phase 13 recap

Phase 13 — what's new:
- Subject gained an `isPinned` field, plus `SubjectService.togglePin()`
  and `watchPinnedForSemester()` — the plan's "Pinned Subjects" needed
  somewhere to actually live. Toggle it from a new pin icon in the
  Subject Workspace app bar; already-pinned subjects also show a pin
  instead of the usual chevron in the Subjects list
- New `DashboardService` (`lib/core/services/dashboard_service.dart`)
  assembles Home's other four sections from data every earlier phase
  already stores, nothing new to persist for them:
  - **Today's Classes** — today's `TimetableEntry` rows for the active
    semester, subject/teacher names resolved
  - **Recent Uploads** — lectures + resources across every subject,
    newest 10, sorted by capture/upload time
  - **Pending AI** — lectures with no `ocrText` saved yet (per Phase
    9's "never OCR again" rule, that means "never actually reviewed"),
    so Phase 10's AI actions have nothing to run against until they are
  - **Pinned Subjects** — exactly the list above
  - (Quick Search has no data of its own — it's a shortcut into the
    Search tab)
- Real `HomeScreen` — loaded once per active semester (not a live
  StreamBuilder, since it spans several collections at once) with
  pull-to-refresh and a manual refresh button. Tapping a class opens
  its subject on the right Theory/Lab/Tutorial tab; tapping an upload
  or a pending lecture opens it directly

### Action needed before this run (Phase 13, for history)

New field on an existing Isar model (`Subject.isPinned`), so
**`build_runner` needs to run** again:

```
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

No new packages, no new permissions.

Phase 12 — what's new:
- New `SearchService` (`lib/core/services/search_service.dart`) — the
  plan's "Normalization -> shows Lecture, PDF, PPT, Assignment,
  Syllabus. No filename searching": for every subject in the active
  semester, checks each lecture's OCR text, each resource's extracted
  text, and the syllabus's extracted text (not just names) for a
  case-insensitive match, and returns a `SearchResult` per hit with a
  short excerpt around the match. `SearchResultKind` covers
  lecture/pdf/ppt/word/image/syllabus — Assignment isn't built until
  Phase 14, so it isn't a case yet, but adding one later is one enum
  value plus one branch
- Real `SearchScreen` — one search box, debounced 350ms, results as
  cards showing the type icon, subject name, and matched excerpt.
  Tapping a lecture result opens `LectureDetailScreen` directly;
  tapping a resource or syllabus result opens the Subject Workspace
  already on the right tab
- `SubjectWorkspaceScreen` gained an optional `initialSection` param so
  Search (and anything else later) can deep-link straight to Resources
  or Syllabus instead of always landing on Theory

### Action needed before this run (Phase 12)

No new packages, no new Isar model, no new permissions — this phase
only reads through existing services.

Phase 11 — what's new:
- New `ChatMessage` Isar model (`lib/core/models/chat_message.dart`) —
  one row per turn, scoped to a `subjectId`; only completed exchanges
  are stored (a failed Gemini call shows inline but never gets written,
  so a retry can't resend a broken turn back as "history")
- New `ChatRole` enum (`lib/core/models/enums.dart`) — `user` /
  `assistant`, same forward-declared-alongside-the-model pattern as
  `AiAction` in Phase 10
- New `ChatContextService` (`lib/core/services/chat_context_service.dart`)
  — assembles one subject's grounding text: syllabus, every resource
  with extracted text, and every OCR'd lecture across Theory/Lab/
  Tutorial, newest lectures first. Soft-capped at 60k characters so a
  semester's worth of material still makes a fast, cheap request
- New `ChatService` (`lib/core/services/chat_service.dart`) — owns the
  message history and prompt assembly per the plan's "Explain BCNF ->
  Gemini searches Lecture + PDF + PPT + Syllabus -> Answer"; the actual
  HTTP call still goes through Phase 10's `GeminiService.generateRaw`,
  so there's still exactly one place in the app that talks to Gemini.
  Sends the last 12 turns as conversation history alongside the fresh
  context block, so follow-up questions work without resending
  everything each time
- New `AiChatTab` (`lib/screens/subject_tabs/ai_chat_tab.dart`) — the
  actual chat UI: message bubbles, a typing indicator, inline
  missing-key/error handling with a Settings link (same pattern as
  Phase 10's lecture screen), and a Clear Chat action. This one widget
  is used in two places — embedded as the Subject Workspace's "AI Chat"
  tab (now real, no longer a Phase-11 placeholder), and inside the new
  `SubjectChatScreen` for the top-level nav entry point
- Top-level "AI Chat" nav tab (`lib/screens/ai_chat_screen.dart`) is now
  a subject picker rather than a placeholder — chat is always scoped to
  one subject per the plan ("chat only with DBMS"), so this screen's
  only job is choosing which one before opening `SubjectChatScreen`

### Action needed before this run (Phase 11)

New Isar model, so **`build_runner` needs to run**:

```
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

No new packages, no new permissions.

Phase 10 — what's new:
- New `AiAction` enum (`lib/core/models/enums.dart`) — the plan's five
  per-lecture actions (Explain, Summarize, Key Points, Important
  Questions, Generate Notes), each carrying its own Gemini prompt
  instruction and icon
- New `GeminiService` (`lib/core/services/gemini_service.dart`) — the
  only place in the app that calls the Gemini HTTP API
  (`v1beta/models/gemini-2.5-flash:generateContent`), mirroring how
  `TextExtractionService` is the sole ML Kit/PDF touchpoint.
  `runAction()` builds the prompt for one of the five actions;
  `generateRaw()` is the lower-level entry point Phase 11's subject
  chat will reuse directly. Throws `GeminiApiKeyMissingException`
  specifically (rather than a generic error) so the screen can offer a
  direct link to Settings
- New `ApiKeyService` (`lib/core/services/api_key_service.dart`) — the
  Gemini API key lives in the platform keystore/keychain via
  `flutter_secure_storage`, not in Isar. Everything else in this app is
  deliberately plaintext-on-disk per the plan; the API key is the one
  exception
- Real `SettingsScreen` — Phase 16's "Gemini API Key" row pulled
  forward since Phase 10 needs it to function; the rest of Settings
  (OCR language, theme, export/import, backup, cache) stays a preview
  list until Phase 16
- `LectureDetailScreen` now has an "AI Features" section below the OCR
  text box: a chip per action, a result card with Copy (clipboard) and
  Share (native share sheet via `share_plus`) buttons. Actions run
  against whatever's currently in the text editor, not necessarily the
  saved `ocrText` — so fixing an OCR typo and immediately tapping
  "Explain" works without a separate save step first
- Missing-API-key and network/API-error states are both handled in the
  result area, with a one-tap link to Settings for the former

### Action needed before this run (Phase 10)

Three new packages (`http`, `flutter_secure_storage`, `share_plus`), so
run `flutter pub get` before this one. No new Isar model, so **no
`build_runner` re-run needed**. No new Android/iOS permission entries
either — `flutter create` already adds `INTERNET` to the Android
manifest by default, and this phase only shares plain text (not
files), so `share_plus` needs no extra setup.

Get a free Gemini API key from
[Google AI Studio](https://aistudio.google.com/apikey), then paste it
into Settings → Gemini API Key inside the running app — nothing to
configure in code.

Phase 9 — what's new:
- New `LectureDetailScreen` (`lib/screens/lecture_detail_screen.dart`) —
  opens automatically right after any lecture photo is saved (from both
  the Lectures tab and Quick Capture), and also when tapping an
  existing lecture from the grid. It runs OCR the *first* time only,
  shows the result in an editable text box next to the photo, and a
  "Save Text" button commits whatever the person edited it to
- New `LectureService.updateOcrText` — always writes a value, even an
  empty string, so `Lecture.ocrText == null` (not reviewed yet) can be
  told apart from `Lecture.ocrText == ''` (reviewed, edited down to
  nothing) — the plan's "Never OCR again" means a lecture that's been
  through review once shouldn't get silently re-OCR'd, even if the
  person cleared the text on purpose
- A manual "re-run OCR" button is still available in the app bar for
  the rare case a person genuinely wants a fresh pass (e.g. after
  realizing the photo itself needed retaking) — this is the one place
  OCR *can* run again, and only on explicit request
- Tapping the photo in the detail screen still opens the same
  pinch-to-zoom full-screen view Phase 7 had
- No schema changes (the `ocrText` field was already added in Phase 7
  in anticipation of this), so **no `build_runner` re-run needed**

Phase 8 — what's new:
- **Quick Capture**: a new floating action button on the Subjects screen
  (no need to open a subject first) that implements the plan's two
  cases exactly:
  1. If the current day/time matches a slot on the timetable — say,
     Monday 10:10 and DBMS Theory is scheduled — a dialog suggests it:
     one tap ("Use DBMS") saves it there, or "Choose Different Subject"
     falls through to picking manually.
  2. If nothing's scheduled right now (the plan's "9 PM" example), a
     "Choose Subject" sheet lists every subject in the active semester;
     once picked, the session type is still automatic — Lab if that
     time-of-day matches one of the subject's Lab slots on any day,
     Theory otherwise.
- New `SmartDetectionService` — `detectNow()` for case 1 (wraps
  `TimetableService.findSlotAt`, which Phase 3 had already stubbed out
  with a "used by Phase 8" comment), `fallbackSessionType()` for case 2
- `TimetableService` gained `hasLabAtTimeOfDay` for the case-2 fallback
- `LectureService`'s capture methods were split into `pickImage()` and
  `saveCapturedImage()` — Quick Capture needs to pick the photo *before*
  it knows the subject, unlike Phase 7's subject-scoped flow which
  always knows both upfront. The original `captureFromCamera`/
  `pickFromGallery` methods still work exactly as before, just composed
  from the same two new pieces internally
- No schema changes, so **no `build_runner` re-run needed** for this
  phase — first phase since 4 where that's true

### Note on how "automatic" this really is

The plan says "no manual work," and case 1 delivers that when your
timetable is accurate and you upload during class. But phones don't
know your day plan changed, so Quick Capture always shows a suggestion
to confirm rather than silently filing the photo — one tap either way,
never zero, so a wrong guess can't quietly land in the wrong subject.

Phase 7 — what's new:

Phase 7 — what's new:
- **Lectures tab is real**: a Theory/Lab/Tutorial switcher at the top,
  then a photo grid for whichever one is selected. "Add Lecture" opens
  a Camera/Gallery choice sheet, same pattern as the plan's own
  `+ -> Camera / Gallery` flow
- New `Lecture` model (`lib/core/models/lecture.dart`) — subject, session
  type, auto-generated `lectureCode`, image path, captured/created
  timestamps, and an `ocrText` field left null until Phase 9 fills it in
  (same forward-declared-field pattern `Subject.code` used ahead of
  this phase)
- New `LectureService` — generates IDs like `DBMS_T_005`
  (`<subject code>_<session initial>_<count padded to 3 digits>`,
  Tutorial uses `TU` so it can't collide with Theory's `T`) and falls
  back to the subject's name when no short code has been set yet; stores
  the photo under `Subject/<Theory|Lab|Tutorial>/Images/`, reusing
  `FileStorageService.copyWithUniqueName` from Phase 6 so two lectures
  can never collide or overwrite each other
- Tapping a lecture opens it full-screen with pinch-to-zoom
  (`InteractiveViewer`); each tile also has a delete action that removes
  both the Isar row and the file on disk
- No new permissions needed — Phase 3 already added camera + gallery
  access for the timetable photo flow, and this reuses the exact same
  `image_picker` setup

### Action needed before this run (Phase 7)

Phase 7 adds another new Isar model (`Lecture`), so this run also needs
a `build_runner` re-run:

```
dart run build_runner build --delete-conflicting-outputs
```

### What's manual here, and why Phase 8 doesn't change it

This tab's Theory/Lab/Tutorial switcher stays manual even after Phase 8
lands the automatic version below — you're already inside a specific
subject at this point, so there's nothing left to detect, and manual
override needs to always be available since automatic detection won't
be right 100% of the time. Phase 8 instead adds a *separate* entry
point (Quick Capture, from the Subjects screen) for the case where you
haven't picked a subject yet at all.

Phase 6 — what's new:
- **Resources tab is real**: upload any mix of PDF/PPT/Word/Image files
  into a subject in one go (multi-select). PDFs and images get their
  text extracted automatically on upload, same as Syllabus; PPT/Word
  are stored as-is for now — the plan itself flags PPT text extraction
  as "later," and no Word extractor is in the stack yet either
- New `Resource` model (`lib/core/models/resource.dart`) — many per
  subject, storing exactly what the plan specifies: name, path, subject,
  type, extracted text — the file itself always stays on disk, never
  duplicated into Isar
- New `ResourceService.uploadAll` — copies every picked file into
  `Subject/Resources/<PDFs|PPTs|Word|Images>/`, silently skips anything
  with an unrecognized extension (and tells the person which files were
  skipped), and never overwrites a same-named file — unlike Syllabus,
  a subject can have many resources, so collisions get "(1)", "(2)"
  suffixes instead of clobbering the earlier upload
- **Refactored**: each workspace tab's real content now lives in its own
  file under `lib/screens/subject_tabs/` (`schedule_tab.dart`,
  `syllabus_tab.dart`, `resources_tab.dart`) — `subject_workspace_screen.dart`
  is back down to just the app bar + tab shell. Three real tabs in one
  file was starting to get unwieldy, and Lectures/Assignments/AI Chat
  will add three more before long, so this was the right point to split

### Action needed before this run (Phase 6)

Phase 6 adds another new Isar model (`Resource`), so this run also
needs a `build_runner` re-run — same command as Phase 5:

```
dart run build_runner build --delete-conflicting-outputs
```

Phase 5 — what's new:
- **Syllabus tab is real** in the Subject Workspace: upload a PDF once
  and its text is extracted automatically (no separate "extract" step —
  it happens right after the file is saved)
- New `Syllabus` model (`lib/core/models/syllabus.dart`) — one per
  subject; re-uploading replaces the old file and re-extracts the text
  rather than creating a second record
- New `FileStorageService` — the app's first real on-disk file writer.
  It owns the folder layout from the plan:
  `AcademicAssistant/Semester_<N>/<Subject>/Syllabus/Syllabus.pdf`, and
  is written generically so Phase 6 (Resources) and Phase 7 (Lectures)
  can reuse it as-is for their own subfolders
- New `SyllabusService` — copies the picked PDF into that folder,
  extracts its text, and upserts the one `Syllabus` row for the subject
- **Renamed** `TimetableExtractionService` → `TextExtractionService`
  (same code, same singleton ML Kit recognizer): it was never really
  timetable-specific, and Syllabus needed the exact same PDF-text-
  extraction call, so it made sense to generalize the name now rather
  than end up with two near-duplicate services once Phase 6/9 land
- Workspace app bar shows the subject's uploaded-syllabus state; the
  extracted text can be reviewed in a scrollable sheet without leaving
  the tab

### Action needed before this run

Phase 5 adds a new Isar model (`Syllabus`), so unlike Phase 4, this one
*does* need a `build_runner` re-run:

```
dart run build_runner build --delete-conflicting-outputs
```

### Why `file_storage_service.dart` showed up a phase early

The plan puts general file storage in Phase 6 (Resources), but Syllabus
is the first feature that needs to actually keep a file around
permanently — Phase 3's timetable upload only ever needed the *text*,
never the file. Building the folder-structure logic now, generically,
means Phase 6 only has to reuse it for PPTs/PDFs/Word/images instead of
writing it twice.

Phase 4 — what's new:
- **Subject Workspace** screen (`lib/screens/subject_workspace_screen.dart`):
  tapping a subject in the Subjects list now opens a full workspace with
  the 8 tabs from the plan — Theory, Lab, Tutorial, Resources, Lectures,
  Assignments, Syllabus, AI Chat
- **Theory/Lab/Tutorial tabs are real**, not placeholders: each one reads
  the subject's `TimetableEntry` rows straight from Phase 3's data,
  filtered by session type and sorted by day/time, with the teacher name
  resolved and shown per slot. A slot can be removed straight from its
  tile if the timetable turns out wrong.
- **Resources / Lectures / Assignments / AI Chat tabs** are labeled
  placeholders that name the exact phase that builds them (6, 7, 14,
  11) — the full tab bar is clickable end-to-end today even though most
  tabs have no feature yet (Syllabus joined the "real" side in Phase 5,
  above).
- **Subject code**: added `Subject.code` editing (tap the tag icon in the
  workspace app bar) — this is the short code Phase 7 will use to build
  lecture IDs like `DBMS_T_005`. Optional; subjects work fine without one.
- New reusable widgets: `TimetableEntryTile` (schedule row with teacher
  lookup + delete) and `EditSubjectCodeSheet` (bottom sheet for the code)
- Service additions: `SubjectService.getById/watchById/updateCode`,
  `TeacherService.getById`, `TimetableService.watchForSubject` — no
  schema changes, so no `build_runner` re-run is needed for this phase

Phase 3 — what's new:
- New models: `Subject`, `Teacher`, `TimetableEntry`, plus shared
  `Weekday`/`SessionType` enums
- `TimetableExtractionService` — real OCR (Google ML Kit) for photos,
  real text extraction (Syncfusion PDF) for PDFs
- `TimetableParser` — heuristic line-by-line parser that pulls out day,
  time range, subject name, Theory/Lab/Tutorial, and teacher name from
  raw text
- `TimetableService`, `SubjectService`, `TeacherService` — commit
  reviewed rows into the database, auto-creating Subjects and Teachers
  and de-duplicating by name (no double "DBMS" entries just because it
  appears on 3 different days)
- **Upload Timetable** screen: take a photo / choose from gallery /
  choose a PDF → extraction spinner → an editable review list of every
  row detected (tap any row to fix day/time/subject/teacher, or delete
  a bad one, or add a manual row) → Save
- **Subjects** screen is now real: it requires an active semester, then
  shows every subject that's been created, with a shortcut to upload a
  timetable

### Why a review step, even though the plan says "no manual work"

Timetables come in wildly different layouts and photo quality varies a
lot, so no parser gets every row right every time. Rather than silently
creating wrong subjects/times, the app extracts everything automatically
and shows it for a quick one-tap confirm — you only touch a row if
something looks off. This keeps the spirit of "no manual work" (most
users just tap Save) while avoiding bad data quietly entering the
database.

### Phase 1 & 2 recap

Phase 1:
- Flutter project skeleton with the exact folder structure from the plan
  (`core/models`, `core/database`, `core/services`, `screens`, `widgets`,
  `utils`, `providers`, `assets`)
- App-wide theme (light + dark, Material 3)
- Bottom-navigation shell wiring all 6 top-level sections: Home, Semester,
  Subjects, AI Chat, Search, Settings
- Isar database service that initializes on app start
- Basic state management (Provider) wired up

Phase 2:
- `Semester` Isar model (`lib/core/models/semester.dart`): name, semester
  number, start date, end date, active flag
- `SemesterService` — create / list / set-active / delete, fully wired to
  Isar (`lib/core/services/semester_service.dart`)
- `SemesterProvider` — live-streams the semester list to the UI
- Real **Semester** screen: shows all created semesters, highlights which
  one is "Active", lets you set-active or delete via a menu
- "New Semester" form (bottom sheet) with Name, Semester Number, Start
  Date, and End Date fields, with validation (end date must be after
  start date)

## How to run this on your machine

This sandbox can't run the Flutter SDK, so you'll need to open this folder
in your own environment (Android Studio, VS Code, or terminal with Flutter
installed).

### One-time setup (do this before Phase 3's first run)

This drop only ever contained `lib/` + `pubspec.yaml` — no `android/` or
`ios/` folders, since those are normally generated by the Flutter CLI. As
of Phase 3 the app needs real camera/gallery/file access, so those
platform folders and their permission entries now matter. From inside
this project folder:

```bash
flutter create .          # safe to run even with existing lib/pubspec.yaml —
                           # it only fills in the missing android/ios/etc folders
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Then add these permission entries (only needed once):

**`android/app/src/main/AndroidManifest.xml`** — inside the `<manifest>` tag, above `<application>`:
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```

**`ios/Runner/Info.plist`** — inside the outermost `<dict>`:
```xml
<key>NSCameraUsageDescription</key>
<string>Used to take photos of your timetable and lecture notes.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Used to pick timetable and lecture images from your gallery.</string>
```

Then, every time you run it:
```bash
flutter run
```

If a new model gets added in a later phase, re-run the build_runner command
above — that's the only recurring step.

## Roadmap (this is where we're headed)

- [x] Phase 1 — Project Setup (Foundation)
- [x] Phase 2 — Semester Setup
- [x] Phase 3 — Timetable Upload
- [x] Phase 4 — Subject Workspace
- [x] Phase 5 — Upload Syllabus
- [x] Phase 6 — Resource Manager
- [x] Phase 7 — Lecture Upload
- [x] Phase 8 — Smart Subject Detection
- [x] Phase 9 — OCR
- [x] Phase 10 — AI Features
- [x] Phase 11 — Subject AI Chat
- [x] Phase 12 — Search
- [x] Phase 13 — Dashboard
- [x] Phase 14 — Assignment Manager
- [x] Phase 15 — Revision
- [x] Phase 16 — Settings
