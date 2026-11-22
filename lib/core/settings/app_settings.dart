import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppAppearance { system, light, dark }

class AppSettings {
  const AppSettings({
    this.appearance = AppAppearance.dark,
    this.budgetWarning = true,
    this.budgetExceeded = true,
    this.highSpendingWeek = true,
    this.smartCheckIn = true,
  });

  final AppAppearance appearance;
  final bool budgetWarning;
  final bool budgetExceeded;
  final bool highSpendingWeek;
  final bool smartCheckIn;

  AppSettings copyWith({
    AppAppearance? appearance,
    bool? budgetWarning,
    bool? budgetExceeded,
    bool? highSpendingWeek,
    bool? smartCheckIn,
  }) => AppSettings(
    appearance: appearance ?? this.appearance,
    budgetWarning: budgetWarning ?? this.budgetWarning,
    budgetExceeded: budgetExceeded ?? this.budgetExceeded,
    highSpendingWeek: highSpendingWeek ?? this.highSpendingWeek,
    smartCheckIn: smartCheckIn ?? this.smartCheckIn,
  );

  ThemeMode get themeMode => switch (appearance) {
    AppAppearance.system => ThemeMode.system,
    AppAppearance.light => ThemeMode.light,
    AppAppearance.dark => ThemeMode.dark,
  };
}

class AppSettingsController extends Notifier<AppSettings> {
  static const _appearanceKey = 'appearance';
  static const _budgetWarningKey = 'budget_warning';
  static const _budgetExceededKey = 'budget_exceeded';
  static const _highSpendingWeekKey = 'high_spending_week';
  static const _smartCheckInKey = 'smart_check_in';

  @override
  AppSettings build() {
    unawaited(_load());
    return const AppSettings();
  }

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    final storedAppearance = preferences.getString(_appearanceKey);
    state = AppSettings(
      appearance: AppAppearance.values.firstWhere(
        (value) => value.name == storedAppearance,
        orElse: () => AppAppearance.dark,
      ),
      budgetWarning: preferences.getBool(_budgetWarningKey) ?? true,
      budgetExceeded: preferences.getBool(_budgetExceededKey) ?? true,
      highSpendingWeek: preferences.getBool(_highSpendingWeekKey) ?? true,
      smartCheckIn: preferences.getBool(_smartCheckInKey) ?? true,
    );
  }

  Future<void> setAppearance(AppAppearance appearance) async {
    state = state.copyWith(appearance: appearance);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_appearanceKey, appearance.name);
  }

  Future<void> setBudgetWarning(bool value) => _setBool(
    key: _budgetWarningKey,
    value: value,
    update: (settings) => settings.copyWith(budgetWarning: value),
  );

  Future<void> setBudgetExceeded(bool value) => _setBool(
    key: _budgetExceededKey,
    value: value,
    update: (settings) => settings.copyWith(budgetExceeded: value),
  );

  Future<void> setHighSpendingWeek(bool value) => _setBool(
    key: _highSpendingWeekKey,
    value: value,
    update: (settings) => settings.copyWith(highSpendingWeek: value),
  );

  Future<void> setSmartCheckIn(bool value) => _setBool(
    key: _smartCheckInKey,
    value: value,
    update: (settings) => settings.copyWith(smartCheckIn: value),
  );

  Future<void> _setBool({
    required String key,
    required bool value,
    required AppSettings Function(AppSettings) update,
  }) async {
    state = update(state);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(key, value);
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsController, AppSettings>(
      AppSettingsController.new,
    );
