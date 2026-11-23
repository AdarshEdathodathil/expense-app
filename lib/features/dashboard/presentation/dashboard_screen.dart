import 'package:expense_tracker/core/date/year_month.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/settings/app_settings.dart';
import 'package:expense_tracker/core/currency/currency_option.dart';
import 'package:expense_tracker/core/widgets/trace_bottom_navigation.dart';
import 'package:expense_tracker/features/households/presentation/household_settings_page.dart';
import 'package:expense_tracker/features/households/application/household_session.dart';
import 'package:expense_tracker/features/insights/presentation/insights_page.dart';
import 'package:expense_tracker/features/insights/application/selected_insights_month.dart';
import 'package:expense_tracker/features/transactions/application/transaction_providers.dart';
import 'package:expense_tracker/features/transactions/data/transaction_repository.dart';
import 'package:expense_tracker/features/transactions/domain/expense_transaction.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({
    this.initialIndex = 0,
    this.initialInsightsMonth,
    super.key,
  });

  final int initialIndex;
  final YearMonth? initialInsightsMonth;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _scheduleInsightsMonthSync(widget.initialInsightsMonth);
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _selectedIndex = widget.initialIndex;
    }
    if (widget.initialInsightsMonth != null &&
        widget.initialInsightsMonth != oldWidget.initialInsightsMonth) {
      _scheduleInsightsMonthSync(widget.initialInsightsMonth);
    }
  }

  void _scheduleInsightsMonthSync(YearMonth? month) {
    if (month == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || ref.read(selectedInsightsMonthProvider) == month) return;
      ref.read(selectedInsightsMonthProvider.notifier).select(month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final insightsMonth = ref.watch(selectedInsightsMonthProvider);
    final Widget content;
    if (_selectedIndex == 1) {
      final transactions = ref.watch(
        insightsTransactionsProvider(insightsMonth),
      );
      content = transactions.when(
        data: (items) => InsightsPage(
          transactions: items,
          selectedMonth: insightsMonth,
          onMonthChanged: (month) {
            ref.read(selectedInsightsMonthProvider.notifier).select(month);
            context.replace('/?tab=insights&month=${month.routeValue}');
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Could not load insights: $error')),
      );
    } else if (_selectedIndex == 2) {
      content = const HouseholdSettingsPage();
    } else {
      final transactions = ref.watch(transactionsProvider);
      final syncStatus =
          ref.watch(syncStatusProvider).value ?? SyncStatus.syncing;
      content = transactions.when(
        data: (items) => _DashboardBody(items: items, syncStatus: syncStatus),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Could not load data: $error')),
      );
    }

    return Scaffold(
      extendBody: true,
      body: SafeArea(child: content),
      bottomNavigationBar: TraceBottomNavigation(
        selected: switch (_selectedIndex) {
          1 => TraceNavDestination.insights,
          2 => TraceNavDestination.settings,
          _ => TraceNavDestination.home,
        },
        onHome: () => context.replace('/'),
        onTransactions: () => context.go('/transactions'),
        onAdd: () async {
          final destination = await context.push<TraceNavDestination>('/add');
          if (!context.mounted || destination == null) return;
          if (destination == TraceNavDestination.transactions) {
            context.go('/transactions');
            return;
          }
          switch (destination) {
            case TraceNavDestination.insights:
              final month = ref.read(selectedInsightsMonthProvider);
              context.replace('/?tab=insights&month=${month.routeValue}');
            case TraceNavDestination.settings:
              context.replace('/?tab=settings');
            case TraceNavDestination.home:
            case TraceNavDestination.add:
            case TraceNavDestination.transactions:
              context.replace('/');
          }
        },
        onInsights: () {
          final month = ref.read(selectedInsightsMonthProvider);
          context.replace('/?tab=insights&month=${month.routeValue}');
        },
        onSettings: () => context.replace('/?tab=settings'),
      ),
    );
  }
}

class _DashboardBody extends ConsumerStatefulWidget {
  const _DashboardBody({required this.items, required this.syncStatus});

  final List<ExpenseTransaction> items;
  final SyncStatus syncStatus;

  @override
  ConsumerState<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends ConsumerState<_DashboardBody> {
  int _monthlyBudget = 6000000;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final monthly = widget.items.where(
      (item) =>
          item.transactionDate.year == now.year &&
          item.transactionDate.month == now.month,
    );
    final income = monthly
        .where((item) => item.type == TransactionType.income)
        .fold<int>(0, (sum, item) => sum + item.amountMinor);
    final expenses = monthly
        .where((item) => item.type == TransactionType.expense)
        .fold<int>(0, (sum, item) => sum + item.amountMinor);
    final session = ref.watch(householdSessionProvider);
    final defaultCurrency = session == null
        ? 'INR'
        : ref.watch(defaultCurrencyProvider(session.householdId)).value ??
              'INR';
    final money = NumberFormat.currency(
      symbol: currencyOption(defaultCurrency).symbol,
      decimalDigits: 0,
    );
    final memberName = session == null
        ? 'You'
        : ref
                  .watch(
                    currentHouseholdMemberProvider((
                      householdId: session.householdId,
                      userId: session.userId,
                    )),
                  )
                  .value
                  ?.displayName ??
              session.displayName;
    final remoteBudget = session == null
        ? null
        : ref.watch(monthlyBudgetProvider(session.householdId)).value;
    final displayedBudget = remoteBudget ?? _monthlyBudget;
    final alertSettings = ref.watch(appSettingsProvider);
    final budgetExceeded = expenses > displayedBudget;
    final nearingBudget = expenses >= displayedBudget * 0.8;
    final recentItems = widget.items.take(5).toList(growable: false);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          sliver: SliverList.list(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TRACE',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: context.traceOnSurface,
                            fontWeight: FontWeight.w900,
                            fontSize: 36,
                            height: 1,
                            letterSpacing: 5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Leave no expense untraced.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: context.traceMuted,
                            letterSpacing: 0.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: context.traceCard,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: context.traceBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 17,
                          color: AppColors.sage,
                        ),
                        SizedBox(width: 7),
                        Text(
                          memberName,
                          style: TextStyle(
                            color: context.traceOnSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: switch (widget.syncStatus) {
                            SyncStatus.synced => AppColors.sage,
                            SyncStatus.syncing => AppColors.gold,
                            SyncStatus.offline => AppColors.expense,
                          },
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Color(0x5596A487), blurRadius: 8),
                          ],
                        ),
                        child: SizedBox.square(dimension: 7),
                      ),
                      SizedBox(width: 7),
                      Text(
                        switch (widget.syncStatus) {
                          SyncStatus.synced => 'Synced',
                          SyncStatus.syncing => 'Syncing',
                          SyncStatus.offline => 'Offline',
                        },
                        style: TextStyle(
                          color: context.traceMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: context.isTraceDark
                        ? const [AppColors.raisedSlate, Color(0xFF3E3A31)]
                        : const [Color(0xFF435544), Color(0xFF7B6638)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available this month',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      money.format((income - expenses) / 100),
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryMetric(
                            label: 'Income',
                            value: money.format(income / 100),
                            icon: Icons.south_west_rounded,
                            color: AppColors.sage,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _SummaryMetric(
                            label: 'Spent',
                            value: money.format(expenses / 100),
                            icon: Icons.north_east_rounded,
                            color: AppColors.gold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _MonthlyBudgetCard(
                spentMinor: expenses,
                budgetMinor: displayedBudget,
                money: money,
                onManage: () => _manageBudget(money),
              ),
              if ((budgetExceeded && alertSettings.budgetExceeded) ||
                  (!budgetExceeded &&
                      nearingBudget &&
                      alertSettings.budgetWarning)) ...[
                const SizedBox(height: 12),
                _BudgetAlert(
                  exceeded: budgetExceeded,
                  spentMinor: expenses,
                  budgetMinor: displayedBudget,
                  money: money,
                ),
              ],
              const SizedBox(height: 28),
              Text(
                'Latest transactions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
        if (widget.items.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
            sliver: SliverToBoxAdapter(
              child: _EmptyRecentActivity(onAdd: () => context.push('/add')),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
            sliver: SliverList.separated(
              itemCount: recentItems.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index < recentItems.length) {
                  return _TransactionTile(item: recentItems[index]);
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: FilledButton.icon(
                    key: const Key('homeSeeAllTransactionsButton'),
                    onPressed: () => context.go('/transactions'),
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('See all transactions'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _manageBudget(NumberFormat money) async {
    final updatedBudget = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => _ManageBudgetSheet(
        initialBudgetMinor: _monthlyBudget,
        currencySymbol: money.currencySymbol,
      ),
    );
    if (updatedBudget != null && mounted) {
      try {
        final session = ref.read(householdSessionProvider);
        if (session != null) {
          await ref
              .read(firebaseHouseholdServiceProvider)
              .updateMonthlyBudget(
                householdId: session.householdId,
                amountMinor: updatedBudget,
              );
        }
        if (!mounted) return;
        setState(() => _monthlyBudget = updatedBudget);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Monthly budget updated to ${money.format(updatedBudget / 100)}',
            ),
          ),
        );
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update budget: $error')),
        );
      }
    }
  }
}

class _BudgetAlert extends StatelessWidget {
  const _BudgetAlert({
    required this.exceeded,
    required this.spentMinor,
    required this.budgetMinor,
    required this.money,
  });

  final bool exceeded;
  final int spentMinor;
  final int budgetMinor;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final overage = (spentMinor - budgetMinor).clamp(0, spentMinor);
    final color = exceeded ? AppColors.expense : AppColors.gold;
    final message = exceeded
        ? 'You are ${money.format(overage / 100)} over this month’s budget.'
        : 'You have used ${(spentMinor / budgetMinor * 100).round()}% of this month’s budget.';
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: context.isTraceDark ? 0.16 : 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          children: [
            Icon(
              exceeded
                  ? Icons.warning_amber_rounded
                  : Icons.trending_up_rounded,
              color: color,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: context.traceOnSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManageBudgetSheet extends StatefulWidget {
  const _ManageBudgetSheet({
    required this.initialBudgetMinor,
    required this.currencySymbol,
  });

  final int initialBudgetMinor;
  final String currencySymbol;

  @override
  State<_ManageBudgetSheet> createState() => _ManageBudgetSheetState();
}

class _ManageBudgetSheetState extends State<_ManageBudgetSheet> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: (widget.initialBudgetMinor / 100).toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Manage monthly budget',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Set the total your household plans to spend this month.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: context.traceMuted),
            ),
            const SizedBox(height: 18),
            TextField(
              key: const Key('budgetAmountField'),
              controller: _controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Monthly budget',
                prefixText: '${widget.currencySymbol}  ',
                errorText: _errorText,
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 18),
            FilledButton(
              key: const Key('saveBudgetButton'),
              onPressed: _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Save budget'),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final amount = double.tryParse(_controller.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _errorText = 'Enter a valid budget amount');
      return;
    }
    Navigator.of(context).pop((amount * 100).round());
  }
}

class _MonthlyBudgetCard extends StatelessWidget {
  const _MonthlyBudgetCard({
    required this.spentMinor,
    required this.budgetMinor,
    required this.money,
    required this.onManage,
  });

  final int spentMinor;
  final int budgetMinor;
  final NumberFormat money;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = budgetMinor == 0
        ? 0.0
        : (spentMinor / budgetMinor).clamp(0.0, 1.0);
    final remaining = (budgetMinor - spentMinor).clamp(0, budgetMinor);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.traceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.traceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF394338),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.sage,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly budget',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: context.traceOnSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${money.format(spentMinor / 100)} of ${money.format(budgetMinor / 100)} used',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.traceMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: context.traceField,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${money.format(remaining / 100)} remaining',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.sage,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: onManage,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.gold,
                  side: const BorderSide(color: Color(0xFF665A40)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                child: const Text('Manage budget'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      CircleAvatar(
        backgroundColor: color,
        foregroundColor: AppColors.deepNavy,
        child: Icon(icon, size: 20),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.item});

  final ExpenseTransaction item;

  @override
  Widget build(BuildContext context) {
    final isIncome = item.type == TransactionType.income;
    final amount = NumberFormat.currency(
      symbol: currencyOption(item.currency).symbol,
      decimalDigits: 0,
    ).format(item.amountMinor / 100);
    final icons = <String, IconData>{
      'Groceries': Icons.shopping_basket_outlined,
      'Salary': Icons.payments_outlined,
      'Utilities': Icons.bolt_outlined,
      'Transport': Icons.directions_car_outlined,
      'Dining': Icons.restaurant_outlined,
    };

    return Card(
      key: ValueKey('homeTransaction-${item.id}'),
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: isIncome
              ? context.traceIncomeTint
              : context.traceExpenseTint,
          child: Icon(
            icons[item.category] ?? Icons.category_outlined,
            color: isIncome ? AppColors.sage : AppColors.expense,
          ),
        ),
        title: Text(
          item.category,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${item.createdByName} • ${DateFormat('d MMM').format(item.transactionDate)}',
        ),
        trailing: Text(
          '${isIncome ? '+' : '-'}$amount',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isIncome
                ? AppColors.sage
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _EmptyRecentActivity extends StatelessWidget {
  const _EmptyRecentActivity({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
    decoration: BoxDecoration(
      color: context.traceCard,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: context.traceBorder),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.receipt_long_outlined,
          size: 38,
          color: AppColors.sage,
        ),
        const SizedBox(height: 10),
        Text(
          'Your story starts here',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 5),
        Text(
          'Add your first income or expense to see your household activity here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.traceMuted),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add transaction'),
        ),
      ],
    ),
  );
}
