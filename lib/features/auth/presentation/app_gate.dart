import 'package:expense_tracker/core/firebase/firebase_bootstrap.dart';
import 'package:expense_tracker/core/date/year_month.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/auth/presentation/auth_page.dart';
import 'package:expense_tracker/features/dashboard/presentation/dashboard_screen.dart';
import 'package:expense_tracker/features/households/application/household_session.dart';
import 'package:expense_tracker/features/households/presentation/household_setup_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppGate extends ConsumerWidget {
  const AppGate({
    this.initialDashboardIndex = 0,
    this.initialInsightsMonth,
    super.key,
  });

  final int initialDashboardIndex;
  final YearMonth? initialInsightsMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(firebaseBootstrapProvider);
    if (!bootstrap.ready) {
      return FirebaseSetupRequiredPage(error: bootstrap.error);
    }

    return ref
        .watch(authStateProvider)
        .when(
          loading: () => const _LoadingPage(message: 'Checking your account…'),
          error: (error, stack) => _ErrorPage(
            message: 'Could not check your account.',
            details: error.toString(),
          ),
          data: (user) {
            if (user == null) {
              if (ref.read(householdSessionProvider) != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref.read(householdSessionProvider.notifier).clear();
                });
              }
              return const AuthPage();
            }
            return _HouseholdGate(
              user: user,
              initialDashboardIndex: initialDashboardIndex,
              initialInsightsMonth: initialInsightsMonth,
            );
          },
        );
  }
}

class _HouseholdGate extends ConsumerWidget {
  const _HouseholdGate({
    required this.user,
    required this.initialDashboardIndex,
    required this.initialInsightsMonth,
  });

  final User user;
  final int initialDashboardIndex;
  final YearMonth? initialInsightsMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(activeHouseholdIdProvider(user.uid))
        .when(
          loading: () => const _LoadingPage(message: 'Loading your household…'),
          error: (error, stack) => _ErrorPage(
            message: 'Could not load your household.',
            details: error.toString(),
          ),
          data: (householdId) {
            if (householdId == null) return const HouseholdSetupPage();
            return _ActiveHouseholdGate(
              user: user,
              householdId: householdId,
              initialDashboardIndex: initialDashboardIndex,
              initialInsightsMonth: initialInsightsMonth,
            );
          },
        );
  }
}

class _ActiveHouseholdGate extends ConsumerWidget {
  const _ActiveHouseholdGate({
    required this.user,
    required this.householdId,
    required this.initialDashboardIndex,
    required this.initialInsightsMonth,
  });

  final User user;
  final String householdId;
  final int initialDashboardIndex;
  final YearMonth? initialInsightsMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(
          currentHouseholdMemberProvider((
            householdId: householdId,
            userId: user.uid,
          )),
        )
        .when(
          loading: () =>
              const _LoadingPage(message: 'Confirming your membership…'),
          error: (error, stack) => _ErrorPage(
            message: 'Could not confirm your household membership.',
            details: error.toString(),
          ),
          data: (member) {
            if (member == null) {
              return _RemovedHouseholdRecovery(householdId: householdId);
            }

            final session = ref.watch(householdSessionProvider);
            if (session?.householdId != householdId ||
                session?.userId != user.uid ||
                session?.displayName != member.displayName) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref
                    .read(householdSessionProvider.notifier)
                    .activate(
                      HouseholdSession(
                        userId: user.uid,
                        displayName: member.displayName,
                        householdId: householdId,
                      ),
                    );
              });
              return const _LoadingPage(message: 'Opening Trace…');
            }

            return DashboardScreen(
              initialIndex: initialDashboardIndex,
              initialInsightsMonth: initialInsightsMonth,
            );
          },
        );
  }
}

class _RemovedHouseholdRecovery extends ConsumerStatefulWidget {
  const _RemovedHouseholdRecovery({required this.householdId});

  final String householdId;

  @override
  ConsumerState<_RemovedHouseholdRecovery> createState() =>
      _RemovedHouseholdRecoveryState();
}

class _RemovedHouseholdRecoveryState
    extends ConsumerState<_RemovedHouseholdRecovery> {
  late Future<void> _recovery;

  @override
  void initState() {
    super.initState();
    _recovery = _recover();
  }

  Future<void> _recover() async {
    ref.read(householdSessionProvider.notifier).clear();
    await ref
        .read(firebaseHouseholdServiceProvider)
        .clearActiveHouseholdIfMatches(widget.householdId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _recovery,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorPage(
            message: 'Your household access was removed.',
            details: 'Could not refresh your account: ${snapshot.error}',
            onRetry: () => setState(() => _recovery = _recover()),
          );
        }
        return const _LoadingPage(message: 'Refreshing your account…');
      },
    );
  }
}

class FirebaseSetupRequiredPage extends StatelessWidget {
  const FirebaseSetupRequiredPage({this.error, super.key});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    size: 58,
                    color: AppColors.gold,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Firebase setup required',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Trace needs its Firebase project configuration before real accounts and household syncing can start.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.traceMuted, height: 1.5),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 18),
                    SelectableText(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.expense,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 15),
          Text(message, style: TextStyle(color: context.traceMuted)),
        ],
      ),
    ),
  );
}

class _ErrorPage extends StatelessWidget {
  const _ErrorPage({
    required this.message,
    required this.details,
    this.onRetry,
  });

  final String message;
  final String details;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.expense,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(message, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              details,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.traceMuted),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
