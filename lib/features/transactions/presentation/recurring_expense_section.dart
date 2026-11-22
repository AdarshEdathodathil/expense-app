import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/transactions/domain/expense_transaction.dart';
import 'package:flutter/material.dart';

class NeedOrWantSelector extends StatelessWidget {
  const NeedOrWantSelector({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final TransactionPriority value;
  final ValueChanged<TransactionPriority> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Need or Want?',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: context.traceOnSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        SegmentedButton<TransactionPriority>(
          expandedInsets: EdgeInsets.zero,
          segments: const [
            ButtonSegment(
              value: TransactionPriority.need,
              label: Text('Need'),
              icon: Icon(Icons.shield_outlined),
            ),
            ButtonSegment(
              value: TransactionPriority.want,
              label: Text('Want'),
              icon: Icon(Icons.auto_awesome_outlined),
            ),
          ],
          selected: {value},
          onSelectionChanged: (selection) => onChanged(selection.first),
        ),
      ],
    );
  }
}

class RecurringExpenseCard extends StatelessWidget {
  const RecurringExpenseCard({
    required this.enabled,
    required this.frequency,
    required this.mode,
    required this.numberOfPayments,
    required this.onEnabledChanged,
    required this.onFrequencyChanged,
    required this.onModeChanged,
    required this.onPaymentCountChanged,
    super.key,
  });

  final bool enabled;
  final RepeatFrequency frequency;
  final RecurrenceMode mode;
  final int numberOfPayments;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<RepeatFrequency> onFrequencyChanged;
  final ValueChanged<RecurrenceMode> onModeChanged;
  final ValueChanged<int> onPaymentCountChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unit = frequency == RepeatFrequency.monthly ? 'months' : 'weeks';
    final showPaymentCount = mode == RecurrenceMode.installments;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.traceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.traceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recurring Expense',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: context.traceOnSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Switch.adaptive(
                key: const Key('recurringExpenseSwitch'),
                value: enabled,
                onChanged: onEnabledChanged,
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            'Turn this on for expenses that repeat automatically, like rent, subscriptions, or gym payments.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.traceMuted,
              height: 1.5,
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: enabled
                ? Padding(
                    padding: const EdgeInsets.only(top: 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _ConfigLabel('Repeat every'),
                        const SizedBox(height: 9),
                        SegmentedButton<RepeatFrequency>(
                          expandedInsets: EdgeInsets.zero,
                          segments: const [
                            ButtonSegment(
                              value: RepeatFrequency.monthly,
                              label: Text('Monthly'),
                            ),
                            ButtonSegment(
                              value: RepeatFrequency.weekly,
                              label: Text('Weekly'),
                            ),
                          ],
                          selected: {frequency},
                          onSelectionChanged: (selection) =>
                              onFrequencyChanged(selection.first),
                        ),
                        if (frequency == RepeatFrequency.monthly) ...[
                          const SizedBox(height: 20),
                          const _ConfigLabel('Monthly Type'),
                          const SizedBox(height: 9),
                          SegmentedButton<RecurrenceMode>(
                            expandedInsets: EdgeInsets.zero,
                            segments: const [
                              ButtonSegment(
                                value: RecurrenceMode.installments,
                                label: Text('Installments'),
                              ),
                              ButtonSegment(
                                value: RecurrenceMode.ongoing,
                                label: Text('Ongoing'),
                              ),
                            ],
                            selected: {mode},
                            onSelectionChanged: (selection) =>
                                onModeChanged(selection.first),
                          ),
                        ],
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: showPaymentCount
                              ? Padding(
                                  key: ValueKey('$frequency-$mode'),
                                  padding: const EdgeInsets.only(top: 18),
                                  child: _PaymentCountCard(
                                    count: numberOfPayments,
                                    unit: unit,
                                    onChanged: onPaymentCountChanged,
                                  ),
                                )
                              : const SizedBox.shrink(key: ValueKey('ongoing')),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _PaymentCountCard extends StatelessWidget {
  const _PaymentCountCard({
    required this.count,
    required this.unit,
    required this.onChanged,
  });

  final int count;
  final String unit;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Number of Payments',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.traceOnSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select how many $unit of payments should be created.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.traceMuted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$count $unit',
                key: const Key('paymentCountLabel'),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 34,
                decoration: BoxDecoration(
                  color: context.traceField,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.traceBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StepButton(
                      key: const Key('decreasePaymentsButton'),
                      icon: Icons.remove_rounded,
                      enabled: count > 1,
                      onTap: () => onChanged(count - 1),
                    ),
                    const VerticalDivider(width: 1, thickness: 1),
                    _StepButton(
                      key: const Key('increasePaymentsButton'),
                      icon: Icons.add_rounded,
                      enabled: count < 120,
                      onTap: () => onChanged(count + 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: enabled ? onTap : null,
    borderRadius: BorderRadius.circular(11),
    child: SizedBox(
      width: 36,
      height: 34,
      child: Icon(
        icon,
        size: 18,
        color: enabled ? context.traceOnSurface : context.traceMuted,
      ),
    ),
  );
}

class _ConfigLabel extends StatelessWidget {
  const _ConfigLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.labelLarge?.copyWith(
      color: context.traceOnSurface,
      fontWeight: FontWeight.w700,
    ),
  );
}
