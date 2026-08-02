# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SALSA is a Flutter mobile app (Android/iOS) for field technicians servicing convenience stores in Indonesia. Technicians receive tasks, fill in validation forms with photos and measurements, and submit proof of work. Business modules (names appear in code as abbreviations):

- **POS** (`schedule`, `proof_of_service`) — monthly AC maintenance / cleaning
- **SC** (`service_call`) — repair tickets for problem units
- **Installation** (`installation`) — AC installation ("Pasang AC")
- **RRO Cut Off** (`rro_cut_off`)
- **POSF** (`proof_of_service_freezer`) — freezer cleaning ("Cuci Freezer"), newest module, mirrors the POS pattern
- Plus: `dashboard`, `history`, `task_maintenance`, `schedule_calendar`, `auth`, `otp`

UI strings, code comments, and commit messages are in Bahasa Indonesia (commits use prefixes like `fitur:`, `chore:`). Follow that convention.

## Commands

```bash
flutter pub get                                        # install dependencies
flutter run                                            # run on connected device/emulator
flutter analyze                                        # lint (flutter_lints defaults)
dart run build_runner build --delete-conflicting-outputs   # regenerate Hive *.g.dart after model changes
flutter build apk --release                            # release build
```

There is no real test suite — `test/widget_test.dart` is the stale default counter test and does not pass. Verification is manual on-device.

Generated `*.g.dart` files are committed; always regenerate and commit them together with model changes.

`qr_code_scanner` is pinned to a **git fork** (`RomyITCM/qr_code_scanner.git`), not the pub.dev package — don't swap it for the published version, and expect `flutter pub get` to fetch it from GitHub.

## Environment Switching

`lib/components/constants.dart` holds `kBaseUrl`/`kPath` — production vs sandbox is toggled by commenting/uncommenting at the top of the file (whichever pair is uncommented is active; check before relying on it, this flips often). Note: a few repositories (e.g. `dashboard_repository.dart`) hardcode the full URL instead of using the helper — new code must use `getUrl(pathUrl: ..., params: ...)` from `lib/components/shared_function.dart`.

App version lives in `pubspec.yaml` (`version: x.y.z+build`) and must be bumped for releases (the `upgrader` package checks store versions).

## Architecture

### Feature-module layout

Every module is split across three parallel trees:

```
lib/blocs/<module>/<feature>/     # bloc/cubit + event + state + repository (all colocated)
lib/models/<module>/              # data models (+ generated Hive adapters *.g.dart)
lib/screens/<module>/<feature>/   # <feature>_screen.dart + components/<feature>_body_mobile.dart
```

- State management is **flutter_bloc**: Blocs for server-backed lists/details/submits, Cubits for form state (e.g. `posf_form_cubit.dart`).
- Each feature has its own repository class making raw `package:http` calls. Repositories check `AuthStorage.isTokenExpired()` first and dispatch `authBloc.add(LoggedOut())` on expiry; requests send `Authorization: Bearer <token>` from `AuthStorage` (flutter_secure_storage, JWT decoded via `JwtHelper`).
- Navigation is mostly direct `MaterialPageRoute` pushes; `RouteGenerator` only covers login/main. Authenticated flows sit behind `AuthGate` / `AuthGuardPage`.

When adding a feature, copy the structure of an existing sibling module — POSF was built by mirroring POS, and that is the expected approach.

### Offline-first with Hive (the critical invariants)

Task data from the server and user drafts are persisted in Hive boxes so technicians can work with poor connectivity. Box name constants live in `constants.dart` (`k*Box`). Convention per module: a read-only **detail/cache box** (server task data), an **info box** (transaction-level data like PIC + technicians), and an **entry/draft box** (per-unit wizard input).

Adding or changing a Hive model requires ALL of:
1. Annotate with `@HiveType(typeId: N)` — **typeIds are a global registry; never reuse one.** Check existing typeIds across `lib/models/` before picking.
2. Run build_runner to regenerate the `.g.dart`.
3. Register the adapter in `main.dart` → `_registerHiveAdapters()` (uses idempotent `reg()` helper).
4. Open the box in `main.dart` → `_loadRetryableData()` via `_openBoxSafely<T>()` (which self-heals corrupt boxes by deleting them from disk).

**Adding a field to an existing Hive model:** existing records on devices deserialize with `null`/default for the new field. Drafts written before the change can be stale — see the Installation module's stale-draft reconciliation (units are identified solely by `unit_index`).

`DailyHiveClearService` purges previous-month data at startup. Firebase is initialized in `main.dart`'s `_setupOneTimeThings()` (sibling of `_loadRetryableData()`), which also routes uncaught `FlutterError`/`PlatformDispatcher` errors to **Firebase Crashlytics** — production crashes surface there, not in device logs.

### Submit → S3 upload → confirmation pipeline

All submit flows share this shape:

1. Repository POSTs the JSON payload (header with PIC/technician data incl. `technician_*_nik`, plus `items`); photo fields carry **filenames only** (`path.split('/').last`).
2. The response returns **presigned S3 URLs** in `result.detail[].uploads[]`.
3. `uploadAllImagesToS3()` (`lib/components/upload_s3_service.dart`) matches local file paths from the Hive boxes to the presigned URLs and uploads, reporting progress via `UploadProgressCubit`.
4. On success a confirmation call is queued in `ConfirmationService` (`kConfirmationQueueBox`), which retries up to 5 times and is drained at every app startup.
5. Failed photo uploads land in the failed-uploads/partial-cache boxes for retry (`failed_uploads` bloc).

Photos are captured through `photo_capture_service.dart` → compressed (`flutter_image_compress`) → labeled/watermarked (`watermark_service.dart`, burns in photo-type, GPS location, timestamp, technician, and device) before storage.

### Location / PIC-photo geofence validation

Before validating a transaction, the technician takes a **store-PIC photo** ("PIC Toko") that geofences them to the store. `LocationValidationBloc` (`lib/blocs/location_validation/`) is **shared across modules**: it operates on any Hive box whose model implements `IPicPhotoStorable` (`lib/models/common/`) — currently the `*transaction_info`/`*info` models of POS, POSF, and SC. On capture it reads GPS (`Geolocator`), watermarks the photo, and stores a `CapturedImageDetail` (`lib/models/common/`, **typeId 2**) holding `latitude`/`longitude`. `LocationHelper.validateLocation()` (`shared_function.dart`) rejects the photo when it is farther than `kDistance` (**500 m**, `constants.dart`) from the store coordinates.

### Measurement inputs (shared component + conventions)

Every module's numeric readings (suhu, volt, ampere, psi) go through `MeasurementInputWidget` (`lib/components/widgets/`), usually wrapped by `GenericMeasurementInputSection` (POS unit, Installation) or a module-specific section (`sc_measurement_input_section.dart`). Cross-cutting rules baked into these widgets:

- **Foto-dulu-baru-angka:** the number field/slider is locked until a photo is taken; removing the photo resets the value. Screens without photo management (`onImageChanged == null`, e.g. legacy `screens/schedule/…`) are not locked.
- **Value commits on blur** (`onEditingComplete`), not per keystroke.
- **Per-field "Sesuai Foto" confirmation dialog** is opt-in via `enableConfirmDialog` (default off). When on, the committed value is confirmed on blur and the widget reports status via `onConfirmedChanged(bool)`. Screens gate their Save/Selesai/Lanjut button on all measurements being confirmed (see `pos_validation_screen.dart` `_confirmedIds` / `_isStep1Complete`; `proof_of_service_detail_body_mobile.dart` `_tempOutConfirmed`/`roomTempsDone`; POSF `proof_of_service_freezer_validation_body_mobile.dart` `_confirmedIds`/`_measurementsConfirmedForStep`). Currently enabled for POS unit, POS header temps, and POSF (arrival temp + suhu/arus/tegangan); SC still commits-on-blur without the dialog.
- **Skip ("tidak bisa diukur"):** a measurement can be skipped with a reason from the server note master. Reasons flagged `require_remark` (`NoteOption`) additionally require a ≥20-char remark + ≥1 evidence photo (`RemarkPhotoPicker`). These evidence photos are separate Hive fields and separate payload keys (`*_remark_photos*`) that must be wired into both the submit repository and `upload_s3_service.dart`.
- **Header-temp gating (POS detail):** Suhu Luar must be completed before Suhu Dalam unlocks; both before unit validation unlocks — where "completed" = (value+photo+confirmed) OR (skip with complete reason).

When touching measurement flows, changes to the shared widget affect all modules — verify each call site (grep `MeasurementInputWidget(`).

### Backend-pending mocks

Some repositories intentionally return mocked responses because the backend endpoint doesn't exist yet — e.g. `posf_submitted_repository.dart` and `proof_of_service_freezer_detail_repository.dart` (whose `getDetail` returns dummy data; POSF is the newest module and still has gaps). These carry `NOTE(backend):` doc comments describing the real call to swap in — preserve that pattern and those comments. Narrower `NOTE(backend):` comments on individual fields (not full mocks) also appear in `service_call_validation_entry_model_ext.dart`, `pos_submitted_repository.dart`, and `service_call_submitted_repository.dart`.
