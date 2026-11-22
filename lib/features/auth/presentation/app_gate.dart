import 'package:expense_tracker/core/firebase/firebase_bootstrap.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/auth/presentation/auth_page.dart';
import 'package:expense_tracker/features/dashboard/presentation/dashboard_screen.dart';
import 'package:expense_tracker/features/households/application/household_session.dart';
import 'package:expense_tracker/features/households/presentation/household_setup_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppGate extends ConsumerWidget {
  const AppGate({this.initialDashboardIndex = 0, super.key});

  final int initialDashboardIndex;

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
            );
          },
        );
  }
}

class _HouseholdGate extends ConsumerWidget {
  const _HouseholdGate({
    required this.user,
    required this.initialDashboardIndex,
  });

  final User user;
  final int initialDashboardIndex;

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

            final session = ref.watch(householdSessionProvider);
            if (session?.householdId != householdId ||
                session?.userId != user.uid) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref
                    .read(householdSessionProvider.notifier)
                    .activate(
                      HouseholdSession(
                        userId: user.uid,
                        displayName:
                            user.displayName ??
                            user.email?.split('@').first ??
                            'You',
                        householdId: householdId,
                      ),
                    );
              });
              return const _LoadingPage(message: 'Opening Trace…');
            }

            return DashboardScreen(initialIndex: initialDashboardIndex);
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
  const _ErrorPage({required this.message, required this.details});

  final String message;
  final String details;

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
          ],
        ),
      ),
    ),
  );
}
