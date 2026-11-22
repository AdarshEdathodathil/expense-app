import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/households/application/household_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _SetupMode { create, join }

class HouseholdSetupPage extends ConsumerStatefulWidget {
  const HouseholdSetupPage({super.key});

  @override
  ConsumerState<HouseholdSetupPage> createState() => _HouseholdSetupPageState();
}

class _HouseholdSetupPageState extends ConsumerState<HouseholdSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _householdController = TextEditingController(text: 'Our household');
  final _inviteController = TextEditingController();
  _SetupMode _mode = _SetupMode.create;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _householdController.dispose();
    _inviteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final creating = _mode == _SetupMode.create;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set up your household'),
        actions: [
          TextButton(
            onPressed: _busy
                ? null
                : () => ref.read(firebaseHouseholdServiceProvider).signOut(),
            child: const Text('Sign out'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: context.traceCard,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: context.traceBorder),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            creating
                                ? Icons.home_work_outlined
                                : Icons.group_add_outlined,
                            size: 42,
                            color: AppColors.gold,
                          ),
                          const SizedBox(height: 13),
                          Text(
                            creating
                                ? 'Create your shared space'
                                : 'Join your household',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            creating
                                ? 'You will become the owner and can invite your wife after setup.'
                                : 'Use the invitation code sent by the household owner.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: context.traceMuted,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    SegmentedButton<_SetupMode>(
                      expandedInsets: EdgeInsets.zero,
                      segments: const [
                        ButtonSegment(
                          value: _SetupMode.create,
                          label: Text('Create household'),
                        ),
                        ButtonSegment(
                          value: _SetupMode.join,
                          label: Text('Join invitation'),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: _busy
                          ? null
                          : (selection) => setState(() {
                              _mode = selection.first;
                              _error = null;
                            }),
                    ),
                    const SizedBox(height: 20),
                    if (creating)
                      TextFormField(
                        controller: _householdController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Household name',
                          prefixIcon: Icon(Icons.home_outlined),
                        ),
                        validator: (value) =>
                            value == null || value.trim().length < 2
                            ? 'Enter a household name'
                            : null,
                      )
                    else
                      TextFormField(
                        controller: _inviteController,
                        textCapitalization: TextCapitalization.characters,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Invitation code',
                          hintText: 'XXXXXXXXXX',
                          prefixIcon: Icon(Icons.key_rounded),
                        ),
                        validator: (value) =>
                            value == null || value.trim().length < 6
                            ? 'Enter a valid invitation code'
                            : null,
                      ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 17),
                      ),
                      child: _busy
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              creating ? 'Create household' : 'Join household',
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final service = ref.read(firebaseHouseholdServiceProvider);
      if (_mode == _SetupMode.create) {
        await service.createHouseholdForCurrentUser(
          householdName: _householdController.text,
        );
      } else {
        await service.acceptInvitation(code: _inviteController.text);
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
