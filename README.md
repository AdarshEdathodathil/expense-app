# Trace

A Flutter household expense tracker designed for two or more people to record
income and expenses in one shared household.

## Current milestone

- Material 3 household dashboard
- Branded midnight, slate, sage, and gold theme based on the supplied logo
- Native Android, iOS, and web splash screens plus an animated in-app splash
- Monthly income, spending, and available balance calculations
- Recent activity with the member who created each entry
- Working income/expense form with categories, notes, and dates
- Currency values stored as integer paise
- UUIDv7 transaction identifiers for safe offline creation
- Repository boundary ready for a Firestore implementation
- Owner/member household service with email-bound invitation codes
- Realtime Firestore transaction repository for cross-device synchronization
- Firestore access rules and required composite index
- Riverpod state management and GoRouter navigation

The app currently uses `DemoTransactionRepository`, so it runs without cloud
credentials. Demo data is kept in memory and resets when the app restarts.

## Run locally

```powershell
flutter pub get
flutter run
```

## Verification

```powershell
flutter analyze
flutter test
flutter build web
```

## Connect Firebase

1. Create a Firebase project.
2. Install and sign in to the Firebase CLI and FlutterFire CLI.
3. Run `flutterfire configure` from this directory for Android and iOS.
4. Enable Email/Password authentication and create a Firestore database.
5. Initialize Firebase from the generated `firebase_options.dart`.
6. Deploy the included rules and indexes with `firebase deploy --only firestore`.
7. Connect the authentication and household screens to
   `FirebaseHouseholdService`, then override `transactionRepositoryProvider`
   with `FirestoreTransactionRepository` for the active household.
8. Test with two separate accounts and devices before production release.

The backend implementation lives in:

- `lib/features/households/data/firebase_household_service.dart`
- `lib/features/transactions/data/firestore_transaction_repository.dart`
- `firestore.rules`

Do not commit service-account keys or other server credentials. The generated
mobile Firebase configuration identifies the project; Firestore Security Rules
and Authentication provide the data-access boundary.
