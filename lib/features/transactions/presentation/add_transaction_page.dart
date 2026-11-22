import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/currency/currency_option.dart';
import 'package:expense_tracker/core/widgets/trace_bottom_navigation.dart';
import 'package:expense_tracker/features/households/application/household_session.dart';
import 'package:expense_tracker/features/transactions/application/transaction_providers.dart';
import 'package:expense_tracker/features/transactions/domain/expense_transaction.dart';
import 'package:expense_tracker/features/transactions/presentation/recurring_expense_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class AddTransactionPage extends ConsumerStatefulWidget {
  const AddTransactionPage({this.transaction, super.key});

  final ExpenseTransaction? transaction;

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _expenseCategories = <String>[
    'Groceries',
    'Utilities',
    'Transport',
    'Dining',
    'Shopping',
    'Health',
    'Other',
  ];
  final _incomeCategories = <String>[
    'Salary',
    'Business',
    'Interest',
    'Gift',
    'Other',
  ];

  TransactionType _type = TransactionType.expense;
  String _category = 'Groceries';
  DateTime _date = DateTime.now();
  bool _saving = false;
  TransactionPriority _priority = TransactionPriority.need;
  bool _isRecurring = false;
  RepeatFrequency _repeatFrequency = RepeatFrequency.monthly;
  RecurrenceMode _recurrenceMode = RecurrenceMode.installments;
  int _numberOfPayments = 12;

  bool get _editing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;
    if (transaction == null) return;
    _type = transaction.type;
    _category = transaction.category;
    _date = transaction.transactionDate;
    _titleController.text = transaction.note;
    _amountController.text = (transaction.amountMinor / 100).toStringAsFixed(2);
    _priority = transaction.priority ?? TransactionPriority.need;
    final recurrence = transaction.recurrence;
    if (recurrence != null) {
      _isRecurring = true;
      _repeatFrequency = recurrence.frequency;
      _recurrenceMode = recurrence.mode;
      _numberOfPayments = recurrence.numberOfPayments ?? 12;
    }
  }

  static const _categoryIcons = <String, IconData>{
    'Groceries': Icons.shopping_basket_outlined,
    'Utilities': Icons.bolt_outlined,
    'Transport': Icons.directions_car_outlined,
    'Dining': Icons.restaurant_outlined,
    'Shopping': Icons.shopping_bag_outlined,
    'Health': Icons.health_and_safety_outlined,
    'Salary': Icons.account_balance_wallet_outlined,
    'Business': Icons.business_center_outlined,
    'Interest': Icons.savings_outlined,
    'Gift': Icons.card_giftcard_outlined,
    'Other': Icons.category_outlined,
  };

  List<String> get _visibleCategories =>
      _type == TransactionType.expense ? _expenseCategories : _incomeCategories;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpense = _type == TransactionType.expense;
    final session = ref.watch(householdSessionProvider);
    final defaultCurrency = session == null
        ? 'INR'
        : ref.watch(defaultCurrencyProvider(session.householdId)).value ??
              'INR';
    final customCategories = session == null
        ? const <String>[]
        : ref
                  .watch(
                    customCategoriesProvider((
                      householdId: session.householdId,
                      type: _type.name,
                    )),
                  )
                  .value ??
              const <String>[];
    final visibleCategories = [
      ..._visibleCategories,
      ...customCategories.where(
        (category) => !_visibleCategories.any(
          (existing) => existing.toLowerCase() == category.toLowerCase(),
        ),
      ),
    ];

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(_editing ? 'Edit transaction' : 'New transaction'),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 126),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<TransactionType>(
                  expandedInsets: EdgeInsets.zero,
                  segments: const [
                    ButtonSegment(
                      value: TransactionType.expense,
                      label: Text('Expense'),
                      icon: Icon(Icons.north_east_rounded),
                    ),
                    ButtonSegment(
                      value: TransactionType.income,
                      label: Text('Income'),
                      icon: Icon(Icons.south_west_rounded),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: _changeType,
                ),
                const SizedBox(height: 26),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.03, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Column(
                    key: ValueKey(_type),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isExpense ? 'Add Expense' : 'Add Income',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: context.traceOnSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isExpense
                            ? 'Create a new expense with a cleaner, smarter flow.'
                            : 'Record your income with a simple, organized flow.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: context.traceMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                const _SectionLabel(label: 'Title'),
                const SizedBox(height: 9),
                TextFormField(
                  key: const Key('titleField'),
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Title',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a title'
                      : null,
                ),
                const SizedBox(height: 20),
                const _SectionLabel(label: 'Amount'),
                const SizedBox(height: 9),
                TextFormField(
                  key: const Key('amountField'),
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: context.traceOnSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    prefixText: '${currencyOption(defaultCurrency).symbol}  ',
                    hintText: '0.00',
                    prefixStyle: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 22,
                    ),
                  ),
                  validator: (value) {
                    final amount = double.tryParse(value?.trim() ?? '');
                    return amount == null || amount <= 0
                        ? 'Enter a valid amount'
                        : null;
                  },
                ),
                const SizedBox(height: 24),
                const _SectionLabel(label: 'All Categories'),
                const SizedBox(height: 11),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: GridView.builder(
                    key: ValueKey(_type),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: visibleCategories.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 11,
                          mainAxisSpacing: 11,
                          childAspectRatio: 2.25,
                        ),
                    itemBuilder: (context, index) {
                      final category = visibleCategories[index];
                      return _CategoryCard(
                        label: category,
                        icon:
                            _categoryIcons[category] ?? Icons.category_outlined,
                        selected: _category == category,
                        onTap: () => setState(() => _category = category),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('createCategoryButton'),
                  onPressed: _createCategory,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: 0.08,
                    ),
                    side: BorderSide(
                      color: theme.colorScheme.primary.withValues(alpha: 0.35),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create New Category'),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  child: isExpense
                      ? Column(
                          key: const ValueKey('expenseConfiguration'),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 24),
                            NeedOrWantSelector(
                              value: _priority,
                              onChanged: (value) =>
                                  setState(() => _priority = value),
                            ),
                            const SizedBox(height: 20),
                            RecurringExpenseCard(
                              enabled: _isRecurring,
                              frequency: _repeatFrequency,
                              mode: _recurrenceMode,
                              numberOfPayments: _numberOfPayments,
                              onEnabledChanged: (value) =>
                                  setState(() => _isRecurring = value),
                              onFrequencyChanged: (value) =>
                                  setState(() => _repeatFrequency = value),
                              onModeChanged: (value) =>
                                  setState(() => _recurrenceMode = value),
                              onPaymentCountChanged: (value) => setState(
                                () => _numberOfPayments = value.clamp(1, 120),
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(
                          key: ValueKey('incomeConfiguration'),
                        ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.traceOnSurface,
                    side: BorderSide(color: context.traceBorder),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(
                    Icons.calendar_today_outlined,
                    color: AppColors.sage,
                  ),
                  label: Text(DateFormat('EEEE, d MMMM yyyy').format(_date)),
                ),
                const SizedBox(height: 22),
                FilledButton(
                  key: const Key('saveTransactionButton'),
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 17),
                  ),
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _editing
                              ? 'Update transaction'
                              : (isExpense ? 'Save Expense' : 'Save Income'),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: TraceBottomNavigation(
        selected: TraceNavDestination.add,
        onHome: () => context.pop(TraceNavDestination.home),
        onTransactions: () => context.pop(TraceNavDestination.transactions),
        onAdd: () {},
        onInsights: () => context.pop(TraceNavDestination.insights),
        onSettings: () => context.pop(TraceNavDestination.settings),
      ),
    );
  }

  void _changeType(Set<TransactionType> value) {
    setState(() {
      _type = value.first;
      _category = _visibleCategories.first;
    });
  }

  Future<void> _createCategory() async {
    final category = await showDialog<String>(
      context: context,
      builder: (context) => const _CreateCategoryDialog(),
    );
    if (category == null || !mounted) return;
    final categories = _type == TransactionType.expense
        ? _expenseCategories
        : _incomeCategories;
    if (categories.any(
      (existing) => existing.toLowerCase() == category.toLowerCase(),
    )) {
      setState(
        () => _category = categories.firstWhere(
          (existing) => existing.toLowerCase() == category.toLowerCase(),
        ),
      );
      return;
    }
    final session = ref.read(householdSessionProvider);
    if (session == null) {
      setState(() {
        categories.add(category);
        _category = category;
      });
      return;
    }
    try {
      await ref
          .read(firebaseHouseholdServiceProvider)
          .createCustomCategory(
            householdId: session.householdId,
            transactionType: _type.name,
            name: category,
          );
      if (mounted) setState(() => _category = category);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create category: $error')),
      );
    }
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: _date,
    );
    if (selected != null) setState(() => _date = selected);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final amountMinor = (double.parse(_amountController.text.trim()) * 100)
        .round();
    final recurrence = _type == TransactionType.expense && _isRecurring
        ? _recurrenceMode == RecurrenceMode.installments
              ? RecurrenceConfig.installments(
                  frequency: _repeatFrequency,
                  startDate: _date,
                  numberOfPayments: _numberOfPayments,
                )
              : RecurrenceConfig.ongoing(
                  frequency: _repeatFrequency,
                  startDate: _date,
                )
        : null;
    final session = ref.read(householdSessionProvider);
    if (session == null) {
      if (mounted) {
        setState(() {
          _saving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your household session expired.')),
        );
      }
      return;
    }
    final transaction = ExpenseTransaction(
      id: widget.transaction?.id ?? const Uuid().v7(),
      householdId: session.householdId,
      type: _type,
      amountMinor: amountMinor,
      currency:
          widget.transaction?.currency ??
          ref.read(defaultCurrencyProvider(session.householdId)).value ??
          'INR',
      category: _category,
      note: _titleController.text.trim(),
      transactionDate: _date,
      createdBy: session.userId,
      createdByName: session.displayName,
      createdAt: widget.transaction?.createdAt ?? now,
      updatedAt: now,
      priority: _type == TransactionType.expense ? _priority : null,
      recurrence: recurrence,
    );
    try {
      final repository = ref.read(transactionRepositoryProvider);
      if (_editing) {
        await repository.update(transaction);
      } else {
        await repository.add(transaction);
      }
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save transaction: $error')),
        );
      }
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(context).textTheme.labelLarge?.copyWith(
      color: context.traceOnSurface,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: selected ? primary : context.traceCard,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: selected ? primary : context.traceBorder),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 21,
                color: selected
                    ? Theme.of(context).colorScheme.onPrimary
                    : AppColors.sage,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? Theme.of(context).colorScheme.onPrimary
                        : context.traceOnSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateCategoryDialog extends StatefulWidget {
  const _CreateCategoryDialog();

  @override
  State<_CreateCategoryDialog> createState() => _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends State<_CreateCategoryDialog> {
  final _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create category'),
      content: TextField(
        key: const Key('newCategoryField'),
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: 'Category name',
          errorText: _errorText,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Create')),
      ],
    );
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _errorText = 'Enter a category name');
      return;
    }
    Navigator.of(context).pop(value);
  }
}
