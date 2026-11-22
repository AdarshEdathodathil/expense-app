import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/settings/app_settings.dart';
import 'package:expense_tracker/features/households/application/household_session.dart';
import 'package:expense_tracker/features/households/domain/household.dart';
import 'package:expense_tracker/features/households/presentation/currency_selection_page.dart';
import 'package:expense_tracker/core/currency/currency_option.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

class HouseholdSettingsPage extends ConsumerWidget {
  const HouseholdSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(householdSessionProvider);
    if (session == null) {
      return const Center(child: Text('No active household session.'));
    }
    final service = ref.watch(firebaseHouseholdServiceProvider);
    final settings = ref.watch(appSettingsProvider);
    final currency =
        ref.watch(defaultCurrencyProvider(session.householdId)).value ?? 'INR';

    return StreamBuilder<List<HouseholdMember>>(
      stream: service.watchMembers(session.householdId),
      builder: (context, snapshot) {
        final members = snapshot.data ?? const <HouseholdMember>[];
        final currentMembership = members
            .where((member) => member.userId == session.userId)
            .firstOrNull;
        final isOwner = currentMembership?.role == HouseholdRole.owner;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            Text(
              'Settings',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Manage your shared household and account.',
              style: TextStyle(color: context.traceMuted),
            ),
            const SizedBox(height: 24),
            _SettingsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SettingHeading(
                    icon: Icons.contrast_rounded,
                    title: 'Appearance',
                    subtitle: 'Choose how Trace should look on this device.',
                    color: Color(0xFF9A6BFF),
                  ),
                  const SizedBox(height: 18),
                  SegmentedButton<AppAppearance>(
                    expandedInsets: EdgeInsets.zero,
                    segments: const [
                      ButtonSegment(
                        value: AppAppearance.system,
                        label: Text('System'),
                      ),
                      ButtonSegment(
                        value: AppAppearance.light,
                        label: Text('Light'),
                      ),
                      ButtonSegment(
                        value: AppAppearance.dark,
                        label: Text('Dark'),
                      ),
                    ],
                    selected: {settings.appearance},
                    onSelectionChanged: (selection) => ref
                        .read(appSettingsProvider.notifier)
                        .setAppearance(selection.first),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SettingsCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: isOwner
                    ? () => _chooseCurrency(
                        context,
                        ref,
                        session.householdId,
                        currency,
                      )
                    : null,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF263A55),
                  foregroundColor: Color(0xFF70A8FF),
                  child: Icon(Icons.currency_exchange_rounded),
                ),
                title: const Text(
                  'Currency',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  isOwner
                      ? _currencyLabel(currency)
                      : '${_currencyLabel(currency)} • Owner managed',
                ),
                trailing: Icon(
                  isOwner ? Icons.chevron_right_rounded : Icons.lock_outline,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SettingsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SettingHeading(
                    icon: Icons.bolt_rounded,
                    title: 'Smart alerts',
                    subtitle: 'Helpful alerts based on your spending activity.',
                    color: Color(0xFFAA75F5),
                  ),
                  const SizedBox(height: 8),
                  _AlertSwitch(
                    icon: Icons.trending_up_rounded,
                    title: '80% budget warning',
                    subtitle: 'Alert when spending reaches 80% of the budget.',
                    value: settings.budgetWarning,
                    onChanged: ref
                        .read(appSettingsProvider.notifier)
                        .setBudgetWarning,
                  ),
                  _AlertSwitch(
                    icon: Icons.warning_amber_rounded,
                    title: 'Budget exceeded',
                    subtitle: 'Alert when spending goes over the budget.',
                    value: settings.budgetExceeded,
                    onChanged: ref
                        .read(appSettingsProvider.notifier)
                        .setBudgetExceeded,
                  ),
                  _AlertSwitch(
                    icon: Icons.calendar_view_week_rounded,
                    title: 'High spending week',
                    subtitle: 'Alert when this week takes a high budget share.',
                    value: settings.highSpendingWeek,
                    onChanged: ref
                        .read(appSettingsProvider.notifier)
                        .setHighSpendingWeek,
                  ),
                  _AlertSwitch(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Smart check-in',
                    subtitle:
                        'Show a nudge when your spending pace is unusual.',
                    value: settings.smartCheckIn,
                    onChanged: ref
                        .read(appSettingsProvider.notifier)
                        .setSmartCheckIn,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SettingsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.people_outline_rounded,
                        color: AppColors.sage,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Household members',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        '${members.length}',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(child: CircularProgressIndicator())
                  else if (snapshot.hasError)
                    Text(
                      'Could not load members: ${snapshot.error}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    )
                  else
                    ...members.map(
                      (member) => _MemberTile(
                        member: member,
                        isCurrentUser: member.userId == session.userId,
                      ),
                    ),
                  if (isOwner) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const Key('inviteMemberButton'),
                      onPressed: () =>
                          _inviteMember(context, ref, session.householdId),
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text('Invite member'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SettingsCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF3B372E),
                  foregroundColor: AppColors.gold,
                  child: Icon(Icons.person_outline_rounded),
                ),
                title: Text(
                  session.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  isOwner ? 'Household owner' : 'Household member',
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (service.currentUser?.emailVerified != true) ...[
              _SettingsCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF4B4231),
                    foregroundColor: AppColors.gold,
                    child: Icon(Icons.mark_email_unread_outlined),
                  ),
                  title: const Text(
                    'Verify your email',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Verification helps protect your household account.',
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      await service.sendEmailVerification();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Verification email sent.'),
                          ),
                        );
                      }
                    },
                    child: const Text('Send'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            _SettingsCard(child: const _AppVersionCard()),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                ref.read(householdSessionProvider.notifier).clear();
                await service.signOut();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.expense,
                side: const BorderSide(color: Color(0xFF70483E)),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _chooseCurrency(
    BuildContext context,
    WidgetRef ref,
    String householdId,
    String currentCurrency,
  ) async {
    final selected = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) =>
            CurrencySelectionPage(currentCurrency: currentCurrency),
      ),
    );
    if (selected == null || selected == currentCurrency || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(firebaseHouseholdServiceProvider)
          .updateDefaultCurrency(householdId: householdId, currency: selected);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update currency: $error')),
        );
      }
    }
  }

  static String _currencyLabel(String code) => currencyOption(code).label;

  Future<void> _inviteMember(
    BuildContext context,
    WidgetRef ref,
    String householdId,
  ) async {
    final email = await showDialog<String>(
      context: context,
      builder: (context) => const _InviteEmailDialog(),
    );
    if (email == null || !context.mounted) return;

    try {
      final invitation = await ref
          .read(firebaseHouseholdServiceProvider)
          .createInvitation(householdId: householdId, invitedEmail: email);
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Invitation created'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Send this code to $email:'),
              const SizedBox(height: 14),
              SelectableText(
                invitation.code,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Expires ${DateFormat('d MMM yyyy').format(invitation.expiresAt.toLocal())}',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.traceMuted),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: invitation.code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invitation code copied')),
                );
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create invitation: $error')),
      );
    }
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, required this.isCurrentUser});

  final HouseholdMember member;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: CircleAvatar(
      backgroundColor: member.role == HouseholdRole.owner
          ? const Color(0xFF4B4231)
          : const Color(0xFF394338),
      foregroundColor: member.role == HouseholdRole.owner
          ? AppColors.gold
          : AppColors.sage,
      child: Icon(
        member.role == HouseholdRole.owner
            ? Icons.workspace_premium_outlined
            : Icons.person_outline_rounded,
      ),
    ),
    title: Text(
      '${member.displayName}${isCurrentUser ? ' (You)' : ''}',
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
    subtitle: Text(member.email),
    trailing: Text(
      member.role == HouseholdRole.owner ? 'Owner' : 'Member',
      style: TextStyle(
        color: context.traceMuted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: context.traceCard,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: context.traceBorder),
    ),
    child: child,
  );
}

class _SettingHeading extends StatelessWidget {
  const _SettingHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CircleAvatar(
        radius: 25,
        backgroundColor: color.withValues(alpha: 0.16),
        foregroundColor: color,
        child: Icon(icon),
      ),
      const SizedBox(width: 13),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            Text(subtitle, style: TextStyle(color: context.traceMuted)),
          ],
        ),
      ),
    ],
  );
}

class _AlertSwitch extends StatelessWidget {
  const _AlertSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 3),
    leading: Icon(icon, color: AppColors.gold),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(subtitle),
    trailing: Switch(value: value, onChanged: onChanged),
  );
}

class _AppVersionCard extends StatelessWidget {
  const _AppVersionCard();

  @override
  Widget build(BuildContext context) => FutureBuilder<PackageInfo>(
    future: PackageInfo.fromPlatform(),
    builder: (context, snapshot) {
      final package = snapshot.data;
      final version = package == null
          ? 'Loading…'
          : '${package.version} (${package.buildNumber})';
      return Column(
        children: [
          const _SettingHeading(
            icon: Icons.phone_android_rounded,
            title: 'App version',
            subtitle: 'See the version currently installed on this device.',
            color: Color(0xFF6EA3FF),
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Current version',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(version, style: TextStyle(color: context.traceMuted)),
            ],
          ),
        ],
      );
    },
  );
}

class _InviteEmailDialog extends StatefulWidget {
  const _InviteEmailDialog();

  @override
  State<_InviteEmailDialog> createState() => _InviteEmailDialogState();
}

class _InviteEmailDialogState extends State<_InviteEmailDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Invite a member'),
    content: TextField(
      controller: _controller,
      autofocus: true,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      decoration: InputDecoration(labelText: 'Member email', errorText: _error),
      onSubmitted: (_) => _submit(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Create invitation')),
    ],
  );

  void _submit() {
    final email = _controller.text.trim().toLowerCase();
    if (!email.contains('@')) {
      setState(() => _error = 'Enter a valid email');
      return;
    }
    Navigator.of(context).pop(email);
  }
}
