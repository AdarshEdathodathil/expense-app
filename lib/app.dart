import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/settings/app_settings.dart';
import 'package:expense_tracker/features/auth/presentation/app_gate.dart';
import 'package:expense_tracker/features/dashboard/presentation/dashboard_screen.dart';
import 'package:expense_tracker/features/onboarding/presentation/splash_screen.dart';
import 'package:expense_tracker/features/transactions/presentation/add_transaction_page.dart';
import 'package:expense_tracker/features/transactions/domain/expense_transaction.dart';
import 'package:expense_tracker/features/transactions/presentation/transactions_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';

GoRouter _createRouter(Widget? rootOverride) => GoRouter(
  observers: Firebase.apps.isEmpty
      ? const []
      : [FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)],
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        final tab = state.uri.queryParameters['tab'];
        final initialIndex = switch (tab) {
          'insights' => 1,
          'settings' => 2,
          _ => 0,
        };
        final destination = rootOverride is DashboardScreen
            ? DashboardScreen(initialIndex: initialIndex)
            : rootOverride ?? AppGate(initialDashboardIndex: initialIndex);
        return BrandedLaunchScreen(destination: destination);
      },
    ),
    GoRoute(
      path: '/add',
      builder: (context, state) => AddTransactionPage(
        transaction: state.extra is ExpenseTransaction
            ? state.extra as ExpenseTransaction
            : null,
      ),
    ),
    GoRoute(
      path: '/transactions',
      builder: (context, state) => const TransactionsPage(),
    ),
  ],
);

class ExpenseTrackerApp extends ConsumerStatefulWidget {
  const ExpenseTrackerApp({this.rootOverride, super.key});

  final Widget? rootOverride;

  @override
  ConsumerState<ExpenseTrackerApp> createState() => _ExpenseTrackerAppState();
}

class _ExpenseTrackerAppState extends ConsumerState<ExpenseTrackerApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _createRouter(widget.rootOverride);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    return MaterialApp.router(
      title: 'Trace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      routerConfig: _router,
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
