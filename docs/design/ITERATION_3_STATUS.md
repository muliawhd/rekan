# Re:kan — Iteration 3 Status: Academic Onboarding UI & Laravel Integration (`ITERATION_3_STATUS.md`)

**Date**: 2026-11-16  
**Scope**: Iteration 3 — Academic Onboarding UI (`Steps 1–5`), Completion Predicate, Draft Management & Laravel Profile Integration  
**Application Repository**: `D:\Mulia\hackgdgocitb\rekan`

---

## 1. Pre-Implementation Audit Summary

### 1.1 Backend Contract (`services/api/routes/api.php` & `AcademicProfileController.php`)
- **Implemented Routes**:
  - `GET /api/v1/health` & `GET /api/health` (`HealthController`)
  - `GET /api/v1/me` (`MeController` with `AuthenticateSupabase`)
  - `GET /api/v1/me/academic-profile` (`AcademicProfileController@show` with `AuthenticateSupabase` + `AcademicProfilePolicy@view`)
  - `PUT /api/v1/me/academic-profile` (`AcademicProfileController@update` with `AuthenticateSupabase` + `AcademicProfilePolicy@update`)
- **Verified 10-Field `PUT` Projection & Validation Rules**:
  1. `display_name`: `present`, `nullable`, `string`, `max:100`
  2. `university_id`: `bail`, `present`, `nullable`, `uuid`, `Rule::exists('universities', 'id')`
  3. `program`: `present`, `nullable`, `string`, `max:150`
  4. `semester`: `present`, `nullable`, `integer`, `between:1,20`
  5. `bio`: `present`, `nullable`, `string`, `max:2000`
  6. `mbti_badge`: `present`, `nullable`, `string`, `regex:/^[EI][NS][FT][JP]$/D` (display-only)
  7. `visibility`: `required`, `Rule::in(['private', 'university', 'public'])`
  8. `courses`: `present`, `array`, `list`, `max:100`; `courses.*`: `bail`, `required`, `uuid`, `distinct:ignore_case`, `Rule::exists('courses', 'id')` (must be global `university_id == null` or match `input['university_id']`)
  9. `skills`: `present`, `array`, `list`, `max:100`; `skills.*`: `required`, `array:skill_id,level`; `skills.*.skill_id`: `bail`, `required`, `uuid`, `distinct:ignore_case`, `Rule::exists('skills', 'id')`; `skills.*.level`: `required`, `integer`, `between:1,5`
  10. `preferences`: `required`, `array:study_mode,preferred_language`:
      - `preferences.study_mode`: `present`, `nullable`, `Rule::in(['online', 'in_person', 'hybrid'])`
      - `preferences.preferred_language`: `present`, `nullable`, `string`, `max:35`, `regex:/^[a-z]{2,3}(-[A-Za-z0-9]{2,8})*$/D`
  - Any unknown or protected field (`user_id`, `status`, `created_at`, `interests`, `portfolio`, `availability`) is rejected with `422 VALIDATION_ERROR`.
  - Optional `X-Re-Require-Empty-Profile: true` header atomically rejects writes with `409 PROFILE_NOT_EMPTY` under row lock if the server profile is no longer empty.

---

## 2. Implemented Onboarding Screens & Architecture

| File | Responsibility |
|---|---|
| `apps/mobile/lib/features/academic_profile/domain/academic_onboarding_completion.dart` | Defines `AcademicOnboardingCompletion` (`isComplete`, `missingRequiredFields`), `AcademicOnboardingValidation` (client-side validators matching `AcademicProfileController.php`), and read-only catalog DTOs (`UniversityCatalogItem`, `CourseCatalogItem`, `SkillCatalogItem`, `AcademicCatalogSnapshot`). |
| `apps/mobile/lib/features/academic_profile/presentation/onboarding_draft_controller.dart` | Defines `OnboardingDraftController` (`ChangeNotifier`): manages the 5-step state machine, preserves drafts across step navigation and recoverable `PUT` failures, enforces duplicate-submission locks, preserves untouched fields (`university_id`, `courses`, `skills`, `visibility`), sends `requireEmpty: true` when initializing an empty profile, and wipes drafts immediately on account switch/logout. |
| `apps/mobile/lib/features/academic_profile/presentation/academic_onboarding_page.dart` | Implements `AcademicOnboardingBoundary`, `AcademicOnboardingPage` (`Steps 1–5`), `_OnboardingProgressHeader`, `_OnboardingBottomBar`, and `_CompletedAcademicProfileView` using the canonical Neo-Brutalist components (`RePageScaffold`, `ReBrandMark`, `RePrimaryButton`, `ReSecondaryButton`, `ReTextField`, `ReChip`, `ReSectionHeader`, `ReStatusBanner`). |
| `apps/mobile/lib/features/auth/auth_boundary.dart` & `apps/mobile/lib/app.dart` | Wires `AuthBoundary` (`AuthScreen.authenticated`) to `AcademicOnboardingBoundary` when `profileRepository` is provided while preserving existing auth tests when `profileRepository` is omitted. |

### 2.1 Five-Step Onboarding Flow (`FigCraft id: 760`)
1. **Langkah 1 — Identitas Akademik**:
   - `display_name` (`NAMA TAMPILAN AKADEMIK *`, wajib untuk penyelesaian onboarding, maks. 100 karakter)
   - `bio` (`RINGKASAN AKADEMIK & TUJUAN KOLABORASI (OPSIONAL)`, maks. 2000 karakter — juga menjadi tempat mencatat minat akademik karena skema API tidak memiliki field `interests` terpisah)
   - `mbti_badge` (`BADGE MBTI (OPSIONAL — HANYA TAMPILAN)`, regex `^[EI][NS][FT][JP]$`, diberi keterangan eksplisit bahwa badge ini hanya untuk tampilan profil dan tidak memengaruhi rekomendasi kolaborasi)
2. **Langkah 2 — Universitas, Program Studi & Semester** (sesuai FigCraft `Screen 9` `id: 760`):
   - `university_id` (`UNIVERSITAS / INSTITUSI KAMPUS *`, menampilkan pemilih universitas bila katalog tersedia atau status `KATALOG KAMPUS BELUM TERSEDIA` tanpa memalsukan UUID serta tetap mempertahankan `university_id` yang sudah tersimpan)
   - `program` (`PROGRAM STUDI / JURUSAN *`, wajib untuk penyelesaian onboarding, maks. 150 karakter)
   - `semester` (`JENJANG & SEMESTER AKTIF (1–20) *`, wajib untuk penyelesaian onboarding, bilangan bulat `1–20`, dilengkapi chip cepat `Semester 1..8`)
3. **Langkah 3 — Keahlian dan Minat**:
   - `skills` (`List<SkillSelection>` dengan `skill_id` UUID dan `level` `1–5`, opsional, maks. 100):
     - Menampilkan daftar keahlian yang sudah tersimpan lengkap dengan pengatur level `Lv.1..Lv.5` dan tombol `Hapus`.
     - Menampilkan katalog keahlian bila tersedia, atau banner `KATALOG KEAHLIAN BELUM TERSEDIA` bila endpoint `GET /api/v1/skills` belum aktif.
4. **Langkah 4 — Mata Kuliah Aktif**:
   - `courses` (`List<String>` UUID mata kuliah, opsional, maks. 100):
     - Menampilkan peringatan `TINJAU MATA KULIAH KAMPUS` bila pengguna mengubah `university_id` sementara masih ada mata kuliah tersimpan.
     - Menampilkan mata kuliah terpilih (tetap dipertahankan walaupun katalog belum tersedia) dan pemilih katalog mata kuliah bila tersedia, atau banner `KATALOG MATA KULIAH BELUM TERSEDIA` bila endpoint `GET /api/v1/courses` belum aktif.
5. **Langkah 5 — Preferensi Belajar & Review**:
   - `preferences.study_mode` (`online`, `in_person`, `hybrid`, atau `null` — opsional)
   - `preferences.preferred_language` (kode bahasa BCP-47 maks. 35 karakter — opsional, dengan chip cepat `id`, `en`, `id-ID`)
   - `visibility` (`private` default, `university`, `public` — wajib pada payload `PUT`, mempertahankan pilihan yang sudah tersimpan)
   - **Kartu `Tinjau Profil Akademik`**: menampilkan seluruh 10 field yang akan dikirim, tombol pintas `Ubah` ke Langkah 1–4, indikator kesiapan kelengkapan (`SIAP LENGKAP` / `DRAF PARSIAL`), dan tombol utama `Simpan Profil`.

---

## 3. Missing Catalog API Contracts & Smallest Secure Backend Proposal

### 3.1 Audit of Missing Catalog Endpoints
Inspection of `services/api/routes/api.php` confirms that **no read-only catalog endpoints exist yet** for:
- `universities` (`GET /api/v1/universities`)
- `courses` (`GET /api/v1/courses`)
- `skills` (`GET /api/v1/skills`)

The underlying PostgreSQL tables (`universities`, `courses`, `skills`) and Eloquent models (`App\Modules\Academic\Models\University`, `Course`, `Skill`) already exist from Phases 2C–2D, and `AcademicProfileController.php` enforces `Rule::exists('universities', 'id')`, `Rule::exists('courses', 'id')`, and `Rule::exists('skills', 'id')`.

### 3.2 Selection Controls Currently Blocked on Live Backend Catalog Data
1. **Step 2 — `Universitas / Institusi Kampus` Picker**:
   - Cannot fetch live university options until `GET /api/v1/universities` is implemented and seeded.
   - Current safe behavior: Does not fabricate UUIDs; preserves any existing `university_id` on the user's profile; allows saving `display_name`, `program`, `semester`, `bio`, `mbti_badge`, `preferences`, and `visibility` to the server as a partial draft (`university_id: null`), while keeping onboarding completion (`AcademicOnboardingCompletion.isComplete`) `false` until a real `university_id` is persisted.
2. **Step 3 — `Katalog Keahlian Akademik` Picker**:
   - Cannot fetch new skill UUIDs until `GET /api/v1/skills` is implemented.
   - Current safe behavior: Preserves any existing `skills` (`skill_id` + `level 1..5`), allows updating levels or removing existing skills, and does not block onboarding completion.
3. **Step 4 — `Katalog Mata Kuliah` Picker**:
   - Cannot fetch new course UUIDs until `GET /api/v1/courses` is implemented.
   - Current safe behavior: Preserves any existing `courses` UUIDs, allows removing incompatible courses when `university_id` changes, and does not block onboarding completion.

### 3.3 Smallest Secure Read-Only Laravel Catalog Endpoint Proposal (Awaiting Approval)
When authorized in a future backend task, add three read-only routes inside the existing `Route::middleware(AuthenticateSupabase::class)->group(...)` in `services/api/routes/api.php`:

1. **`GET /api/v1/universities`**:
   - **Query params**: optional `q` (`nullable|string|max:100`), optional `limit` (`integer|between:1,50`, default `20`), optional `ids` (`array|max:50`, `ids.*` `uuid`).
   - **Response (`200 OK`, `Cache-Control: no-store, private`)**:
     ```json
     {
       "data": [
         { "id": "<uuid>", "name": "Institut Teknologi Bandung" }
       ],
       "request_id": "<request-id>"
     }
     ```
   - **Projection**: Excludes `verified_domains` and internal timestamps; ordered deterministically by `name ASC, id ASC`.

2. **`GET /api/v1/courses`**:
   - **Query params**: optional `university_id` (`nullable|uuid|exists:universities,id`), optional `q` (`nullable|string|max:100`), optional `limit` (`integer|between:1,50`, default `20`), optional `ids` (`array|max:100`, `ids.*` `uuid`).
   - **Scope rule**: Returns global courses (`university_id IS NULL`) plus courses belonging to the requested `university_id` (when provided), ordered by `code ASC, id ASC`.
   - **Response (`200 OK`, `Cache-Control: no-store, private`)**:
     ```json
     {
       "data": [
         {
           "id": "<uuid>",
           "university_id": "<uuid-or-null>",
           "code": "IF2210",
           "name": "Pemrograman Berorientasi Objek"
         }
       ],
       "request_id": "<request-id>"
     }
     ```

3. **`GET /api/v1/skills`**:
   - **Query params**: optional `q` (`nullable|string|max:100`), optional `limit` (`integer|between:1,50`, default `20`), optional `ids` (`array|max:100`, `ids.*` `uuid`).
   - **Response (`200 OK`, `Cache-Control: no-store, private`)**:
     ```json
     {
       "data": [
         { "id": "<uuid>", "normalized_name": "flutter" }
       ],
       "request_id": "<request-id>"
     }
     ```

---

## 4. Validation & Test Results

- **Formatting (`dart format lib test`)**: Clean (`0` unformatted files).
- **Static Analysis (`flutter analyze`)**: **`No issues found!`**
- **Automated Tests (`flutter test`)**: **`57 passed, 0 failed`** (`52` existing tests + `5` new Iteration 3 onboarding test suites in `test/academic_onboarding_test.dart`):
  - Completion predicate (`display_name`, `university_id`, `program`, `semester` required; optional fields never block).
  - Step navigation (`1..5` forward, back, direct step jump), required & optional field validation, draft preservation across steps, and untouched field preservation (`university_id`, `courses`, `skills`, `visibility`).
  - Duplicate submission prevention (`saving` lock), recoverable `422` / `409 PROFILE_NOT_EMPTY` / network error draft retention, and account-switch draft invalidation.
  - Full 5-step onboarding widget flow (`AuthBoundary` + `AcademicOnboardingBoundary` -> Steps 1–5 -> Review & Save -> Completed Profile View -> `Perbarui Profil Akademik`).
  - Missing catalog fallback notices (`KATALOG KAMPUS BELUM TERSEDIA`, `KATALOG KEAHLIAN BELUM TERSEDIA`, `KATALOG MATA KULIAH BELUM TERSEDIA`) and `2.0x` large-text scaling on `320×640` viewport without overflow.
- **Git Whitespace Check (`git diff --check`)**: Clean (`exit code 0`).
- **E2E Note**: All Iteration 3 tests run against mocked/in-memory API transports in `flutter test`; no live device E2E claim is made.
