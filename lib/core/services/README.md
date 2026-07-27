# core/services

- `semester_service.dart` ✅ (Phase 2 — all Semester CRUD)
- `subject_service.dart` ✅ (Phase 3 — find-or-create Subject by name; Phase 4 added getById/watchById/updateCode)
- `teacher_service.dart` ✅ (Phase 3 — find-or-create Teacher by name; Phase 4 added getById)
- `text_extraction_service.dart` ✅ (Phase 3 — OCR for images / text extraction for PDFs; renamed from `timetable_extraction_service.dart` in Phase 5 since it's now shared by Syllabus too, not just the timetable; Phase 9 reuses `extractFromImage` as-is for lecture photos)
- `timetable_service.dart` ✅ (Phase 3 — commits reviewed rows, reads back saved timetable; Phase 4 added watchForSubject; Phase 8 added findSlotAt/hasLabAtTimeOfDay for smart detection)
- `file_storage_service.dart` ✅ (Phase 5, moved up from its original Phase 6 slot — Syllabus needed real on-disk storage first; Phase 6 Resources reuses this as-is)
- `syllabus_service.dart` ✅ (Phase 5 — upload/replace/delete the one syllabus PDF per subject, extract its text once)
- `resource_service.dart` ✅ (Phase 6 — upload/delete many PDF/PPT/Word/Image files per subject, extracting text for PDF/Image)
- `lecture_service.dart` ✅ (Phase 7 — camera/gallery capture, auto-generated lecture codes like `DBMS_T_005`, delete; Phase 8 split capture into `pickImage`/`saveCapturedImage` so quick-capture can pick first and decide the subject/session after; Phase 9 added `updateOcrText`)
- `smart_detection_service.dart` ✅ (Phase 8 — matches current day/time against the timetable; falls back to a "Lab timing" time-of-day check when nothing's scheduled right now)
- `api_key_service.dart` ✅ (Phase 10 — secure-storage wrapper for the Gemini API key; the one thing in this app that's deliberately NOT plaintext-on-disk like everything else)
- `gemini_service.dart` ✅ (Phase 10 — the only place that calls the Gemini HTTP API; `runAction` covers the five per-lecture actions, `generateRaw` is reused as-is by Phase 11's subject chat)
- `chat_context_service.dart` ✅ (Phase 11 — assembles one subject's lectures/resources/syllabus text into the Gemini context for chat)
- `chat_service.dart` ✅ (Phase 11 — stores/streams chat history per subject, calls Gemini via `chat_context_service` + `gemini_service`)
- `search_service.dart` ✅ (Phase 12 — normalized search across lectures/resources/assignments/syllabus by name and extracted text)
- `dashboard_service.dart` ✅ (Phase 13 — assembles Today's Classes / Recent Uploads / Pending AI / Pinned Subjects for Home, purely from data other services already store)
- `assignment_service.dart` ✅ (Phase 14 — upload/delete assignment PDFs, set Pending/Submitted status; overdue is derived, never stored)
- `revision_service.dart` ✅ (Phase 15 — gathers starred lectures across a semester's subjects; also generates combined revision notes via `gemini_service.dart`, built now rather than left for "later" as the plan allowed)
- `settings_service.dart` ✅ (Phase 16 — the `AppSettings` singleton row: theme preference, OCR script, backup folder path; deliberately doesn't touch the Gemini key, that stays in `api_key_service.dart`)
- `backup_service.dart` ✅ (Phase 16 — Export/Import Database via Isar's `copyToFile`, choosing a Backup Folder and copying every subject's files + a DB snapshot into it, and Clear Cache — scoped strictly to the OS temp directory so it can never touch a subject's actual files)

`text_extraction_service.dart` gained a small Phase 16 update: the ML
Kit recognizer is now rebuilt from the `OcrScript` setting whenever it
changes, instead of being hardcoded to Latin.

All 16 phases from the plan are now built.
