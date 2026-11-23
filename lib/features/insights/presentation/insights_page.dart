import 'package:expense_tracker/core/date/year_month.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/currency/currency_option.dart';
import 'package:expense_tracker/features/households/application/household_session.dart';
import 'package:expense_tracker/features/insights/domain/monthly_insights_summary.dart';
import 'package:expense_tracker/features/transactions/domain/expense_transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class InsightsPage extends ConsumerWidget {
  const InsightsPage({
    required this.transactions,
    this.selectedMonth,
    this.onMonthChanged,
    super.key,
  });

  final List<ExpenseTransaction> transactions;
  final YearMonth? selectedMonth;
  final ValueChanged<YearMonth>? onMonthChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final month = selectedMonth ?? YearMonth.fromDate(now);
    final summary = MonthlyInsightsSummary.calculate(
      transactions: transactions,
      month: month,
      now: now,
    );
    final monthly = summary.transactions;
    final income = summary.incomeMinor;
    final expenses = summary.expenseMinor;
    final categories = summary.categoryTotals;
    final expenseItems = summary.expenseItems;
    final previousMonth = month.previous.start;
    final previousExpenses = summary.previousExpenseMinor;
    final weeklySpending = summary.weeklySpending;
    final memberSpending = summary.memberSpending;
    final needSpending = summary.needSpendingMinor;
    final wantSpending = summary.wantSpendingMinor;
    final session = ref.watch(householdSessionProvider);
    final budget = session == null
        ? 6000000
        : summary.isCurrentMonth
        ? ref.watch(monthlyBudgetProvider(session.householdId)).value ?? 6000000
        : ref
                  .watch(
                    historicalMonthlyBudgetProvider((
                      householdId: session.householdId,
                      month: month,
                    )),
                  )
                  .value ??
              6000000;
    final currency = session == null
        ? 'INR'
        : ref.watch(defaultCurrencyProvider(session.householdId)).value ??
              'INR';
    final money = NumberFormat.currency(
      symbol: currencyOption(currency).symbol,
      decimalDigits: 0,
    );
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final daysRemaining = (daysInMonth - now.day + 1).clamp(1, daysInMonth);
    final budgetRemaining = (budget - expenses).clamp(0, budget);
    final dailyAllowance = budgetRemaining ~/ daysRemaining;
    final projectedMonthEnd = summary.projectedMonthEndMinor;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        Text(
          'Insights',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        _MonthSelector(
          month: month,
          currentMonth: YearMonth.fromDate(now),
          onChanged: onMonthChanged,
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: _InsightMetric(
                label: 'Income',
                amount: money.format(income / 100),
                color: AppColors.sage,
                icon: Icons.south_west_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InsightMetric(
                label: 'Expenses',
                amount: money.format(expenses / 100),
                color: AppColors.expense,
                icon: Icons.north_east_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _InsightMetric(
          label: 'Net balance',
          amount: money.format((income - expenses) / 100),
          color: AppColors.gold,
          icon: Icons.account_balance_wallet_outlined,
          wide: true,
        ),
        const SizedBox(height: 12),
        _BudgetHealthCard(
          spentMinor: expenses,
          budgetMinor: budget,
          remainingMinor: budgetRemaining,
          dailyAllowanceMinor: dailyAllowance,
          daysRemaining: daysRemaining,
          isCurrentMonth: summary.isCurrentMonth,
          money: money,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DetailMetric(
                label: 'Transactions',
                value: '${monthly.length}',
                icon: Icons.receipt_long_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DetailMetric(
                label: 'Average expense',
                value: expenseItems.isEmpty
                    ? '—'
                    : money.format(expenses / expenseItems.length / 100),
                icon: Icons.analytics_outlined,
              ),
            ),
          ],
        ),
        if (categories.isNotEmpty) ...[
          const SizedBox(height: 12),
          _DetailMetric(
            label: 'Top spending category',
            value:
                '${categories.first.key} · ${money.format(categories.first.value / 100)}',
            icon: Icons.workspace_premium_outlined,
            wide: true,
          ),
        ],
        const SizedBox(height: 26),
        Text(
          'Monthly comparison',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        _ComparisonCard(
          currentMinor: expenses,
          previousMinor: previousExpenses,
          money: money,
          currentLabel: DateFormat('MMMM').format(month.start),
          previousLabel: DateFormat('MMMM').format(previousMonth),
        ),
        const SizedBox(height: 16),
        _TrendCard(values: weeklySpending, money: money),
        const SizedBox(height: 16),
        _MemberSpendingCard(
          values: memberSpending,
          total: expenses,
          money: money,
        ),
        const SizedBox(height: 16),
        _NeedWantCard(
          needMinor: needSpending,
          wantMinor: wantSpending,
          totalMinor: expenses,
          money: money,
        ),
        const SizedBox(height: 16),
        _ProjectionCard(
          projectedMinor: projectedMonthEnd,
          budgetMinor: budget,
          isCurrentMonth: summary.isCurrentMonth,
          monthLabel: DateFormat('MMMM').format(month.start),
          money: money,
        ),
        const SizedBox(height: 26),
        Text(
          'Spending by category',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        if (categories.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.traceCard,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: context.traceBorder),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.donut_large_outlined,
                  color: AppColors.sage,
                  size: 38,
                ),
                SizedBox(height: 10),
                Text('No expenses recorded this month.'),
              ],
            ),
          )
        else
          ...categories.map(
            (category) => _CategoryInsight(
              name: category.key,
              amount: money.format(category.value / 100),
              progress: expenses == 0 ? 0 : category.value / expenses,
            ),
          ),
      ],
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.month,
    required this.currentMonth,
    required this.onChanged,
  });

  static const earliestMonth = YearMonth(2020, DateTime.january);

  final YearMonth month;
  final YearMonth currentMonth;
  final ValueChanged<YearMonth>? onChanged;

  @override
  Widget build(BuildContext context) {
    final canGoBack = month.compareTo(earliestMonth) > 0;
    final canGoForward = month.compareTo(currentMonth) < 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              key: const Key('previousInsightsMonthButton'),
              tooltip: 'Previous month',
              onPressed: onChanged != null && canGoBack
                  ? () => onChanged!(month.previous)
                  : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('insightsMonthPickerButton'),
                onPressed: onChanged == null
                    ? null
                    : () async {
                        final selected = await showModalBottomSheet<YearMonth>(
                          context: context,
                          useSafeArea: true,
                          showDragHandle: true,
                          builder: (context) => _MonthPickerSheet(
                            initialMonth: month,
                            currentMonth: currentMonth,
                          ),
                        );
                        if (selected != null) onChanged!(selected);
                      },
                icon: const Icon(Icons.calendar_month_outlined, size: 19),
                label: Text(
                  DateFormat('MMMM yyyy').format(month.start),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            IconButton(
              key: const Key('nextInsightsMonthButton'),
              tooltip: 'Next month',
              onPressed: onChanged != null && canGoForward
                  ? () => onChanged!(month.next)
                  : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        if (month != currentMonth)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 2),
            child: TextButton.icon(
              key: const Key('currentInsightsMonthButton'),
              onPressed: onChanged == null
                  ? null
                  : () => onChanged!(currentMonth),
              icon: const Icon(Icons.today_rounded, size: 17),
              label: const Text('Back to current month'),
            ),
          ),
      ],
    );
  }
}

class _MonthPickerSheet extends StatefulWidget {
  const _MonthPickerSheet({
    required this.initialMonth,
    required this.currentMonth,
  });

  final YearMonth initialMonth;
  final YearMonth currentMonth;

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = widget.initialMonth.year;
  }

  @override
  Widget build(BuildContext context) {
    final years = [
      for (
        var year = _MonthSelector.earliestMonth.year;
        year <= widget.currentMonth.year;
        year++
      )
        year,
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Choose month',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              DropdownButton<int>(
                value: _year,
                items: years
                    .map(
                      (year) =>
                          DropdownMenuItem(value: year, child: Text('$year')),
                    )
                    .toList(),
                onChanged: (year) {
                  if (year != null) setState(() => _year = year);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: DateTime.monthsPerYear,
            itemBuilder: (context, index) {
              final candidate = YearMonth(_year, index + 1);
              final enabled = candidate.compareTo(widget.currentMonth) <= 0;
              final selected = candidate == widget.initialMonth;
              return FilledButton.tonal(
                onPressed: enabled
                    ? () => Navigator.pop(context, candidate)
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: selected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                ),
                child: Text(DateFormat.MMM().format(candidate.start)),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InsightMetric extends StatelessWidget {
  const _InsightMetric({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    this.wide = false,
  });

  final String label;
  final String amount;
  final Color color;
  final IconData icon;
  final bool wide;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(wide ? 20 : 17),
    decoration: BoxDecoration(
      color: context.traceCard,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: context.traceBorder),
    ),
    child: wide
        ? Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: TextStyle(color: context.traceMuted)),
              ),
              Text(
                amount,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 21),
              const SizedBox(height: 16),
              Text(label, style: TextStyle(color: context.traceMuted)),
              const SizedBox(height: 5),
              Text(
                amount,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
  );
}

class _BudgetHealthCard extends StatelessWidget {
  const _BudgetHealthCard({
    required this.spentMinor,
    required this.budgetMinor,
    required this.remainingMinor,
    required this.dailyAllowanceMinor,
    required this.daysRemaining,
    required this.isCurrentMonth,
    required this.money,
  });

  final int spentMinor;
  final int budgetMinor;
  final int remainingMinor;
  final int dailyAllowanceMinor;
  final int daysRemaining;
  final bool isCurrentMonth;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final progress = (spentMinor / budgetMinor).clamp(0.0, 1.0);
    final overBudget = spentMinor > budgetMinor;
    final accent = overBudget ? AppColors.expense : AppColors.gold;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.traceCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.traceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Budget health',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${(spentMinor / budgetMinor * 100).round()}%',
                style: TextStyle(color: accent, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: context.traceField,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 13),
          Text(
            overBudget
                ? '${money.format((spentMinor - budgetMinor) / 100)} over budget'
                : '${money.format(remainingMinor / 100)} remaining',
            style: TextStyle(color: accent, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text(
            isCurrentMonth
                ? 'You can spend about ${money.format(dailyAllowanceMinor / 100)} per day for the next $daysRemaining days.'
                : 'Recorded spending against the available monthly budget.',
            style: TextStyle(color: context.traceMuted),
          ),
        ],
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({
    required this.currentMinor,
    required this.previousMinor,
    required this.money,
    required this.currentLabel,
    required this.previousLabel,
  });
  final int currentMinor;
  final int previousMinor;
  final NumberFormat money;
  final String currentLabel;
  final String previousLabel;
  @override
  Widget build(BuildContext context) {
    final change = previousMinor == 0
        ? null
        : (currentMinor - previousMinor) / previousMinor;
    final up = (change ?? 0) > 0;
    return _InsightCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Expenses compared with last month',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            change == null
                ? 'No spending recorded in $previousLabel.'
                : '${(change.abs() * 100).round()}% ${up ? 'higher' : 'lower'} than $previousLabel',
            style: TextStyle(
              color: change == null
                  ? context.traceMuted
                  : (up ? AppColors.expense : AppColors.sage),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${money.format(currentMinor / 100)} in $currentLabel • ${money.format(previousMinor / 100)} in $previousLabel',
            style: TextStyle(color: context.traceMuted),
          ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.values, required this.money});
  final List<int> values;
  final NumberFormat money;
  @override
  Widget build(BuildContext context) {
    final maxValue = values.fold<int>(
      0,
      (max, value) => value > max ? value : max,
    );
    return _InsightCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly spending trend',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            'Your spending pattern across this month.',
            style: TextStyle(color: context.traceMuted),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 104,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(5, (index) {
                final value = values[index];
                final factor = maxValue == 0 ? 0.08 : value / maxValue;
                final barHeightFactor = (62 * factor + 5) / 67;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          value == 0 ? '—' : money.format(value / 100),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: context.traceMuted,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Expanded(
                          child: FractionallySizedBox(
                            alignment: Alignment.bottomCenter,
                            heightFactor: barHeightFactor,
                            child: Container(
                              key: ValueKey('weekly-spending-bar-$index'),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'W${index + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.traceMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberSpendingCard extends StatelessWidget {
  const _MemberSpendingCard({
    required this.values,
    required this.total,
    required this.money,
  });
  final Map<String, int> values;
  final int total;
  final NumberFormat money;
  @override
  Widget build(BuildContext context) => _InsightCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Spending by member',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        if (values.isEmpty)
          Text(
            'No expenses to compare yet.',
            style: TextStyle(color: context.traceMuted),
          )
        else
          ...values.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        money.format(entry.value / 100),
                        style: TextStyle(color: context.traceMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: total == 0 ? 0 : entry.value / total,
                    minHeight: 7,
                    backgroundColor: context.traceField,
                    valueColor: const AlwaysStoppedAnimation(AppColors.sage),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

class _NeedWantCard extends StatelessWidget {
  const _NeedWantCard({
    required this.needMinor,
    required this.wantMinor,
    required this.totalMinor,
    required this.money,
  });
  final int needMinor;
  final int wantMinor;
  final int totalMinor;
  final NumberFormat money;
  @override
  Widget build(BuildContext context) => _InsightCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Need vs. Want',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _NeedWantValue(
                label: 'Needs',
                value: money.format(needMinor / 100),
                color: AppColors.sage,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NeedWantValue(
                label: 'Wants',
                value: money.format(wantMinor / 100),
                color: AppColors.gold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: totalMinor == 0 ? 0 : needMinor / totalMinor,
          minHeight: 8,
          backgroundColor: AppColors.gold.withValues(alpha: 0.45),
          valueColor: const AlwaysStoppedAnimation(AppColors.sage),
        ),
      ],
    ),
  );
}

class _ProjectionCard extends StatelessWidget {
  const _ProjectionCard({
    required this.projectedMinor,
    required this.budgetMinor,
    required this.isCurrentMonth,
    required this.monthLabel,
    required this.money,
  });
  final int projectedMinor;
  final int budgetMinor;
  final bool isCurrentMonth;
  final String monthLabel;
  final NumberFormat money;
  @override
  Widget build(BuildContext context) {
    final over = projectedMinor > budgetMinor;
    final color = over ? AppColors.expense : AppColors.sage;
    return _InsightCard(
      child: Row(
        children: [
          Icon(
            isCurrentMonth
                ? Icons.auto_graph_rounded
                : Icons.event_available_rounded,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCurrentMonth
                      ? 'Projected month-end spending'
                      : 'Final spending for $monthLabel',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  isCurrentMonth
                      ? (over
                            ? 'At this pace, you may exceed budget by ${money.format((projectedMinor - budgetMinor) / 100)}.'
                            : 'At this pace, you are projected to stay within budget.')
                      : (over
                            ? '${money.format((projectedMinor - budgetMinor) / 100)} over the saved monthly budget.'
                            : 'Recorded total for the completed month.'),
                  style: TextStyle(color: context.traceMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            money.format(projectedMinor / 100),
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _NeedWantValue extends StatelessWidget {
  const _NeedWantValue({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(color: context.traceMuted)),
      const SizedBox(height: 3),
      Text(
        value,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    ],
  );
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.traceCard,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: context.traceBorder),
    ),
    child: child,
  );
}

class _DetailMetric extends StatelessWidget {
  const _DetailMetric({
    required this.label,
    required this.value,
    required this.icon,
    this.wide = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool wide;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.traceCard,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: context.traceBorder),
    ),
    child: wide
        ? Row(
            children: [
              Icon(icon, color: AppColors.sage),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label, style: TextStyle(color: context.traceMuted)),
              ),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.sage, size: 20),
              const SizedBox(height: 12),
              Text(label, style: TextStyle(color: context.traceMuted)),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
  );
}

class _CategoryInsight extends StatelessWidget {
  const _CategoryInsight({
    required this.name,
    required this.amount,
    required this.progress,
  });

  final String name;
  final String amount;
  final double progress;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(amount, style: TextStyle(color: context.traceMuted)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: 8,
            backgroundColor: context.traceField,
            valueColor: const AlwaysStoppedAnimation(AppColors.gold),
          ),
        ),
      ],
    ),
  );
}
