import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/currency/currency_option.dart';
import 'package:expense_tracker/core/widgets/trace_bottom_navigation.dart';
import 'package:expense_tracker/features/transactions/application/transaction_providers.dart';
import 'package:expense_tracker/features/exports/transaction_export_service.dart';
import 'package:expense_tracker/features/insights/application/selected_insights_month.dart';
import 'package:expense_tracker/features/transactions/domain/expense_transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

enum _TransactionFilter { all, income, expense }

enum _AmountOrder { recent, highToLow, lowToHigh }

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  _TransactionFilter _filter = _TransactionFilter.all;
  String _query = '';
  String? _category;
  _AmountOrder _amountOrder = _AmountOrder.recent;

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);
    final categorySource = transactions.when(
      data: (items) => items,
      loading: () => const <ExpenseTransaction>[],
      error: (_, _) => const <ExpenseTransaction>[],
    );
    final categories =
        categorySource
            .where(
              (transaction) => switch (_filter) {
                _TransactionFilter.income =>
                  transaction.type == TransactionType.income,
                _TransactionFilter.expense =>
                  transaction.type == TransactionType.expense,
                _TransactionFilter.all => true,
              },
            )
            .map((transaction) => transaction.category)
            .toSet()
            .toList()
          ..sort();

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Transactions',
                      key: const Key('transactionsPageTitle'),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (transactions.hasValue)
                    PopupMenuButton<String>(
                      tooltip: 'Export transactions',
                      onSelected: (value) =>
                          _export(value, transactions.value!),
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'csv', child: Text('Share CSV')),
                        PopupMenuItem(value: 'pdf', child: Text('Share PDF')),
                      ],
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: _filter == _TransactionFilter.all
                          ? Theme.of(context).colorScheme.primary
                          : context.traceCard,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: _filter == _TransactionFilter.all
                            ? Theme.of(context).colorScheme.primary
                            : context.traceBorder,
                      ),
                    ),
                    child: InkWell(
                      key: const Key('allTransactionsButton'),
                      onTap: () => setState(() {
                        _filter = _TransactionFilter.all;
                        _category = null;
                      }),
                      borderRadius: BorderRadius.circular(13),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 17,
                          vertical: 13,
                        ),
                        child: Text(
                          'ALL',
                          style: TextStyle(
                            color: _filter == _TransactionFilter.all
                                ? AppColors.deepNavy
                                : context.traceMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: SegmentedButton<TransactionType>(
                      expandedInsets: EdgeInsets.zero,
                      emptySelectionAllowed: true,
                      segments: const [
                        ButtonSegment(
                          value: TransactionType.income,
                          label: Text('Income'),
                        ),
                        ButtonSegment(
                          value: TransactionType.expense,
                          label: Text('Expense'),
                        ),
                      ],
                      selected: switch (_filter) {
                        _TransactionFilter.income => {TransactionType.income},
                        _TransactionFilter.expense => {TransactionType.expense},
                        _TransactionFilter.all => {},
                      },
                      onSelectionChanged: (selection) => setState(() {
                        _filter = switch (selection.firstOrNull) {
                          TransactionType.income => _TransactionFilter.income,
                          TransactionType.expense => _TransactionFilter.expense,
                          null => _TransactionFilter.all,
                        };
                        _category = null;
                      }),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _CategoryFilterChip(
                            label: 'All categories',
                            selected: _category == null,
                            onSelected: () => setState(() => _category = null),
                          ),
                          ...categories.map(
                            (category) => _CategoryFilterChip(
                              label: category,
                              selected: _category == category,
                              onSelected: () =>
                                  setState(() => _category = category),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuButton<_AmountOrder>(
                    tooltip: 'Sort by amount',
                    icon: const Icon(Icons.swap_vert_rounded),
                    onSelected: (value) => setState(() => _amountOrder = value),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _AmountOrder.recent,
                        child: Text('Most recent'),
                      ),
                      PopupMenuItem(
                        value: _AmountOrder.highToLow,
                        child: Text('Amount: high to low'),
                      ),
                      PopupMenuItem(
                        value: _AmountOrder.lowToHigh,
                        child: Text('Amount: low to high'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: TextField(
                onChanged: (value) => setState(() => _query = value.trim()),
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Search title or category',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            Expanded(
              child: transactions.when(
                data: _buildList,
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Could not load transactions: $error'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: TraceBottomNavigation(
        selected: TraceNavDestination.transactions,
        onHome: () => context.go('/'),
        onTransactions: () {},
        onAdd: _openAddPage,
        onInsights: () {
          final month = ref.read(selectedInsightsMonthProvider);
          context.go('/?tab=insights&month=${month.routeValue}');
        },
        onSettings: () => context.go('/?tab=settings'),
      ),
    );
  }

  Widget _buildList(List<ExpenseTransaction> source) {
    final sorted = [...source]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final filtered = sorted.where((transaction) {
      final matchesType = switch (_filter) {
        _TransactionFilter.all => true,
        _TransactionFilter.income => transaction.type == TransactionType.income,
        _TransactionFilter.expense =>
          transaction.type == TransactionType.expense,
      };
      final query = _query.toLowerCase();
      final matchesQuery =
          query.isEmpty ||
          transaction.note.toLowerCase().contains(query) ||
          transaction.category.toLowerCase().contains(query) ||
          transaction.createdByName.toLowerCase().contains(query);
      return matchesType && matchesQuery;
    }).toList();

    final categoryFiltered = filtered
        .where(
          (transaction) =>
              _category == null || transaction.category == _category,
        )
        .toList();
    switch (_amountOrder) {
      case _AmountOrder.recent:
        break;
      case _AmountOrder.highToLow:
        categoryFiltered.sort((a, b) => b.amountMinor.compareTo(a.amountMinor));
      case _AmountOrder.lowToHigh:
        categoryFiltered.sort((a, b) => a.amountMinor.compareTo(b.amountMinor));
    }

    if (categoryFiltered.isEmpty) {
      return const _EmptyTransactions();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      itemCount: categoryFiltered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _TransactionHistoryCard(
        transaction: categoryFiltered[index],
        onDelete: () => _confirmDelete(categoryFiltered[index]),
        onEdit: () => _openEdit(categoryFiltered[index]),
      ),
    );
  }

  Future<void> _confirmDelete(ExpenseTransaction transaction) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text(
          'This removes it from the household timeline. You can add it again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;
    try {
      await ref.read(transactionRepositoryProvider).delete(transaction.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Transaction deleted')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete transaction: $error')),
        );
      }
    }
  }

  Future<void> _openAddPage() async {
    final destination = await context.push<TraceNavDestination>('/add');
    if (!mounted || destination == null) return;
    switch (destination) {
      case TraceNavDestination.home:
        context.go('/');
      case TraceNavDestination.insights:
        final month = ref.read(selectedInsightsMonthProvider);
        context.go('/?tab=insights&month=${month.routeValue}');
      case TraceNavDestination.settings:
        context.go('/?tab=settings');
      case TraceNavDestination.transactions:
      case TraceNavDestination.add:
        break;
    }
  }

  Future<void> _openEdit(ExpenseTransaction transaction) async {
    await context.push<void>('/add', extra: transaction);
  }

  Future<void> _export(
    String format,
    List<ExpenseTransaction> transactions,
  ) async {
    try {
      if (format == 'csv') {
        await TransactionExportService.shareCsv(transactions);
      } else {
        await TransactionExportService.sharePdf(transactions);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not export transactions: $error')),
      );
    }
  }
}

class _CategoryFilterChip extends StatelessWidget {
  const _CategoryFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    ),
  );
}

class _TransactionHistoryCard extends StatelessWidget {
  const _TransactionHistoryCard({
    required this.transaction,
    required this.onDelete,
    required this.onEdit,
  });

  final ExpenseTransaction transaction;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final amount = NumberFormat.currency(
      symbol: currencyOption(transaction.currency).symbol,
      decimalDigits: 0,
    ).format(transaction.amountMinor / 100);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isIncome
                    ? context.traceIncomeTint
                    : context.traceExpenseTint,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
                color: isIncome ? AppColors.sage : AppColors.expense,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.note.isEmpty
                        ? transaction.category
                        : transaction.note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.traceOnSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${transaction.category} • ${transaction.createdByName} • ${DateFormat('d MMM').format(transaction.transactionDate)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: context.traceMuted),
                  ),
                  if (transaction.recurrence != null ||
                      transaction.priority != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: [
                        if (transaction.priority != null)
                          _StatusBadge(
                            icon:
                                transaction.priority == TransactionPriority.need
                                ? Icons.shield_outlined
                                : Icons.auto_awesome_outlined,
                            label:
                                transaction.priority == TransactionPriority.need
                                ? 'Need'
                                : 'Want',
                          ),
                        if (transaction.recurrence != null)
                          _StatusBadge(
                            icon: Icons.repeat_rounded,
                            label:
                                transaction.recurrence!.frequency ==
                                    RepeatFrequency.monthly
                                ? 'Monthly'
                                : 'Weekly',
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}$amount',
                  style: TextStyle(
                    color: isIncome ? AppColors.sage : context.traceOnSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  iconSize: 20,
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: context.traceField,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: context.traceBorder),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.gold),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: context.traceMuted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: AppColors.sage,
          ),
          const SizedBox(height: 12),
          Text(
            'No transactions here yet',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            'Try another filter or add a new transaction.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.traceMuted),
          ),
        ],
      ),
    ),
  );
}
