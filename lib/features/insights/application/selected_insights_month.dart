import 'package:expense_tracker/core/date/year_month.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectedInsightsMonthController extends Notifier<YearMonth> {
  @override
  YearMonth build() => YearMonth.fromDate(DateTime.now());

  void select(YearMonth month) => state = month;
}

final selectedInsightsMonthProvider =
    NotifierProvider<SelectedInsightsMonthController, YearMonth>(
      SelectedInsightsMonthController.new,
    );
