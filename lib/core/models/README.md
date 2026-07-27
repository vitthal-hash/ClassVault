# core/models

- `semester.dart` ✅ (Phase 2)
- `enums.dart` ✅ (Phase 3 — Weekday, SessionType, shared everywhere; Phase 10 added `AiAction` for the five per-lecture AI actions; Phase 16 added `ThemePreference` and `OcrScript`)
- `subject.dart` ✅ (Phase 3)
- `teacher.dart` ✅ (Phase 3)
- `timetable_entry.dart` ✅ (Phase 3)
- `syllabus.dart` ✅ (Phase 5 — one per subject: file path + extracted text)
- `resource.dart` ✅ (Phase 6 — many per subject: PDF/PPT/Word/Image + optional extracted text)
- `lecture.dart` ✅ (Phase 7 — many per subject: session type, auto-generated code, image path; `ocrText` populated from Phase 9 onward — `null` means not yet reviewed, `''` means reviewed-and-cleared, so OCR is never silently re-run; Phase 15 added `isStarred` — a starred lecture IS the Revision folder's contents, no separate table needed)
- `chat_message.dart` ✅ (Phase 11 — one message per subject chat, `ChatRole` user/assistant)
- `assignment.dart` ✅ (Phase 14 — one per uploaded assignment: title, PDF path, deadline, Pending/Submitted status; `isOverdue` is derived, never stored)
- `app_settings.dart` ✅ (Phase 16 — singleton row, `id = 0`: theme preference, OCR script, backup folder path. Deliberately doesn't hold the Gemini API key — that stays in secure storage via `ApiKeyService`, Phase 10 — so this model only ever holds settings that are fine as plaintext, same as everything else in this app)

Every new model has also been added to the `schemas` list in
`lib/core/database/isar_service.dart`.
