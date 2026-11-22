import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/households/application/household_session.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _AuthMode { signIn, createAccount }

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  _AuthMode _mode = _AuthMode.signIn;
  bool _busy = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final creating = _mode == _AuthMode.createAccount;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/branding/app_logo.png',
                        width: 150,
                        semanticLabel: 'Trace logo',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'TRACE',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 4,
                          ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Leave no expense untraced.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.traceMuted),
                    ),
                    const SizedBox(height: 30),
                    SegmentedButton<_AuthMode>(
                      expandedInsets: EdgeInsets.zero,
                      segments: const [
                        ButtonSegment(
                          value: _AuthMode.signIn,
                          label: Text('Sign in'),
                        ),
                        ButtonSegment(
                          value: _AuthMode.createAccount,
                          label: Text('Create account'),
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
                    const SizedBox(height: 22),
                    if (creating) ...[
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Your name',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) =>
                            value == null || value.trim().length < 2
                            ? 'Enter your name'
                            : null,
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        return !email.contains('@')
                            ? 'Enter a valid email'
                            : null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) => (value?.length ?? 0) < 6
                          ? 'Use at least 6 characters'
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
                          : Text(creating ? 'Create account' : 'Sign in'),
                    ),
                    if (!creating) ...[
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: _busy ? null : _resetPassword,
                        child: const Text('Forgot password?'),
                      ),
                    ],
                    if (creating) ...[
                      const SizedBox(height: 12),
                      Text(
                        'After creating your account, you can create a household as its owner or join an invitation as a member.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.traceMuted,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
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
      if (_mode == _AuthMode.signIn) {
        await service.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await service.createAccount(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _nameController.text,
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = _authMessage(error));
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      setState(
        () => _error = 'Enter your email first, then tap forgot password.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(firebaseHouseholdServiceProvider)
          .sendPasswordResetEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = _authMessage(error));
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not send reset email.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _authMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-credential' => 'Incorrect email or password.',
      'email-already-in-use' => 'An account already uses this email.',
      'weak-password' => 'Choose a stronger password.',
      'network-request-failed' => 'Check your internet connection.',
      _ => error.message ?? 'Authentication failed.',
    };
  }
}
