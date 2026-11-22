import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

Future<void> initializeFirebaseServices() async {
  const webSiteKey = String.fromEnvironment('TRACE_RECAPTCHA_SITE_KEY');
  if (kIsWeb && webSiteKey.isNotEmpty) {
    await FirebaseAppCheck.instance.activate(
      providerWeb: ReCaptchaV3Provider(webSiteKey),
    );
  } else if (!kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kReleaseMode
          ? const AndroidPlayIntegrityProvider()
          : const AndroidDebugProvider(),
      providerApple: kReleaseMode
          ? const AppleAppAttestWithDeviceCheckFallbackProvider()
          : const AppleDebugProvider(),
    );
  }

  await FirebaseAnalytics.instance.logAppOpen();
  if (!kIsWeb) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }
}
