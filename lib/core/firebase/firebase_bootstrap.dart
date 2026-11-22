import 'package:flutter_riverpod/flutter_riverpod.dart';

class FirebaseBootstrapState {
  const FirebaseBootstrapState.ready() : ready = true, error = null;

  const FirebaseBootstrapState.notConfigured(this.error) : ready = false;

  final bool ready;
  final Object? error;
}

final firebaseBootstrapProvider = Provider<FirebaseBootstrapState>(
  (ref) => const FirebaseBootstrapState.notConfigured(
    'Firebase has not been initialized.',
  ),
);
