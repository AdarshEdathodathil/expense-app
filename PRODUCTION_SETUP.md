# Trace production checklist

## Firebase

1. Register the Android debug App Check token printed by a debug build, then
   enable Play Integrity enforcement only after a signed release build is
   registered in Firebase App Check.
   For web, pass the reCAPTCHA v3 site key at build time with
   `flutter build web --dart-define=TRACE_RECAPTCHA_SITE_KEY=...`.
2. Enable Crashlytics and Analytics in the Firebase console.
3. Verify Email/Password authentication and configure the authorized domains.
4. Deploy rules and indexes with `firebase deploy --only firestore`.

## Recurring transactions

The scheduler implementation is in `functions/`. Install dependencies there
and deploy only after moving the Firebase project to Blaze billing. The daily
job is idempotent and runs in `asia-south1`.

## Release signing

Copy `android/key.properties.example` to `android/key.properties`, create a
private upload keystore, and fill in the four values. The release Gradle build
refuses to use debug signing when a release task is requested.

## Security tests

Run `npm install` and `npm run test:rules` from `emulator_tests/`. The suite
starts the Firestore emulator and checks owner/member/outsider access.

## Privacy

Review `PRIVACY.md`, replace the support placeholder, and publish it at a stable
HTTPS URL before store submission.
