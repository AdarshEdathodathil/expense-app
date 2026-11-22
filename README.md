# Trace

Trace is a Flutter expense tracker for households. Members use their own
accounts to share an income and expense ledger, review spending, and manage
household settings.

## Current status

The app is implemented as a Firebase-backed Flutter application. Firebase is
initialized at startup using the platform options in `lib/firebase_options.dart`.
If initialization or required services fail, Trace shows a setup error screen
instead of loading the ledger.

Available app features include:

- Email/password sign-in and household creation or joining with an invitation
- Shared, realtime Firestore transactions with income and expense categories,
  dates, notes, and integer-paise currency values
- Dashboard totals, recent activity, and spending insights
- Household member and currency settings
- Recurring expense definitions and a scheduled Cloud Function for generating
  occurrences
- CSV/PDF transaction export and share support
- Light/dark/system themes, onboarding splash, and accessibility coverage
- Firebase App Check, Analytics, and Crashlytics integration

The repository also includes Firestore security rules and indexes, Flutter
tests, and Firestore emulator rule tests. Recurring transaction scheduling
requires deploying the Cloud Function on a Firebase Blaze project. Store
release preparation remains: configure and verify production Firebase/App Check,
publish the privacy policy with a real support contact, and configure release
signing. See [PRODUCTION_SETUP.md](PRODUCTION_SETUP.md) for the checklist.

## Run locally

Requirements: Flutter/Dart SDK versions compatible with `pubspec.yaml`, plus a
configured Firebase project for sign-in and shared data.

```powershell
flutter pub get
flutter run
```

The project is currently associated with Firebase project `expense-tracker-10f12`.
To use another project, run `flutterfire configure` and update the Firebase CLI
project selection as needed. Android's native Firebase configuration is
generated at `android/app/google-services.json` by the FlutterFire setup.

For web App Check, provide the reCAPTCHA v3 key at build time:

```powershell
flutter run -d chrome --dart-define=TRACE_RECAPTCHA_SITE_KEY=<site-key>
```

## Verification

```powershell
flutter analyze
flutter test
flutter build web
```

Run Firestore security rule tests from `emulator_tests/`:

```powershell
npm install
npm run test:rules
```

## Backend and release setup

Deploy Firestore rules and indexes with `firebase deploy --only firestore`.
The scheduled recurring expense function is in `functions/`; see its README
and [PRODUCTION_SETUP.md](PRODUCTION_SETUP.md) before deploying. Production
release steps also cover App Check enrollment, observability, signing, and
privacy policy publication.

Do not commit service-account keys, upload keystores, or other server secrets.
