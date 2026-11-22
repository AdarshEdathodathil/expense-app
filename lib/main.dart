import 'package:expense_tracker/app.dart';
import 'package:expense_tracker/core/firebase/firebase_bootstrap.dart';
import 'package:expense_tracker/core/firebase/firebase_services.dart';
import 'package:expense_tracker/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseBootstrapState bootstrap;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await initializeFirebaseServices();
    bootstrap = const FirebaseBootstrapState.ready();
  } catch (error) {
    bootstrap = FirebaseBootstrapState.notConfigured(error);
  }
  runApp(
    ProviderScope(
      overrides: [firebaseBootstrapProvider.overrideWithValue(bootstrap)],
      child: const ExpenseTrackerApp(),
    ),
  );
}
