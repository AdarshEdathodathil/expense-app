import 'dart:ui';

import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

enum TraceNavDestination { home, transactions, add, insights, settings }

class TraceBottomNavigation extends StatelessWidget {
  const TraceBottomNavigation({
    required this.selected,
    required this.onHome,
    required this.onTransactions,
    required this.onAdd,
    required this.onInsights,
    required this.onSettings,
    super.key,
  });

  final TraceNavDestination selected;
  final VoidCallback onHome;
  final VoidCallback onTransactions;
  final VoidCallback onAdd;
  final VoidCallback onInsights;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isTraceDark;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: isDark ? const Color(0x660A1017) : const Color(0x22000000),
              blurRadius: 28,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            key: const Key('bottomNavigationBackdrop'),
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: 76,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? const [Color(0xD91B2632), Color(0xD924303D)]
                      : const [Color(0xCCFEFDFC), Color(0xCCF7F4ED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: context.traceNavBorder),
              ),
              child: Row(
                children: [
                  _NavItem(
                    label: 'Home',
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home_rounded,
                    selected: selected == TraceNavDestination.home,
                    onTap: onHome,
                  ),
                  _NavItem(
                    label: 'Transactions',
                    icon: Icons.receipt_long_outlined,
                    selectedIcon: Icons.receipt_long_rounded,
                    selected: selected == TraceNavDestination.transactions,
                    onTap: onTransactions,
                  ),
                  _NavItem(
                    key: const Key('addTransactionButton'),
                    label: 'Add',
                    icon: Icons.add_circle_outline_rounded,
                    selectedIcon: Icons.add_circle_rounded,
                    selected: selected == TraceNavDestination.add,
                    onTap: onAdd,
                  ),
                  _NavItem(
                    label: 'Insights',
                    icon: Icons.auto_graph_outlined,
                    selectedIcon: Icons.auto_graph_rounded,
                    selected: selected == TraceNavDestination.insights,
                    onTap: onInsights,
                  ),
                  _NavItem(
                    label: 'Settings',
                    icon: Icons.tune_outlined,
                    selectedIcon: Icons.tune_rounded,
                    selected: selected == TraceNavDestination.settings,
                    onTap: onSettings,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).colorScheme.primary;
    final inactiveColor = context.traceMuted;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: 'Go to $label',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  size: 23,
                  color: selected ? activeColor : inactiveColor,
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(
                        color: selected ? activeColor : inactiveColor,
                        fontSize: 10.5,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
