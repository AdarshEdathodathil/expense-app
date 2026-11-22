import 'package:expense_tracker/features/households/data/firebase_household_service.dart';
import 'package:expense_tracker/features/households/domain/household.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HouseholdSession {
  const HouseholdSession({
    required this.userId,
    required this.displayName,
    required this.householdId,
  });

  final String userId;
  final String displayName;
  final String householdId;
}

class HouseholdSessionController extends Notifier<HouseholdSession?> {
  @override
  HouseholdSession? build() => null;

  void activate(HouseholdSession session) => state = session;

  void clear() => state = null;
}

final householdSessionProvider =
    NotifierProvider<HouseholdSessionController, HouseholdSession?>(
      HouseholdSessionController.new,
    );

final firebaseHouseholdServiceProvider = Provider<FirebaseHouseholdService>(
  (ref) => FirebaseHouseholdService(),
);

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseHouseholdServiceProvider).watchAuthState();
});

final activeHouseholdIdProvider = StreamProvider.family<String?, String>((
  ref,
  userId,
) {
  return ref
      .watch(firebaseHouseholdServiceProvider)
      .watchActiveHouseholdId(userId);
});

final monthlyBudgetProvider = StreamProvider.family<int, String>((
  ref,
  householdId,
) {
  return ref
      .watch(firebaseHouseholdServiceProvider)
      .watchMonthlyBudget(householdId);
});

final defaultCurrencyProvider = StreamProvider.family<String, String>((
  ref,
  householdId,
) {
  return ref
      .watch(firebaseHouseholdServiceProvider)
      .watchDefaultCurrency(householdId);
});

final householdNameProvider = StreamProvider.family<String, String>((
  ref,
  householdId,
) {
  return ref
      .watch(firebaseHouseholdServiceProvider)
      .watchHouseholdName(householdId);
});

final currentHouseholdMemberProvider =
    StreamProvider.family<
      HouseholdMember?,
      ({String householdId, String userId})
    >((ref, request) {
      return ref
          .watch(firebaseHouseholdServiceProvider)
          .watchMember(
            householdId: request.householdId,
            userId: request.userId,
          );
    });

final customCategoriesProvider =
    StreamProvider.family<List<String>, ({String householdId, String type})>((
      ref,
      request,
    ) {
      return ref
          .watch(firebaseHouseholdServiceProvider)
          .watchCustomCategories(
            householdId: request.householdId,
            transactionType: request.type,
          );
    });
