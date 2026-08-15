import 'package:flutter/foundation.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.engine.dart';
import 'package:here_sdk/core.errors.dart';
import '../config/app_config.dart';

/// Initializes the HERE SDK's native engine — required once, before any
/// widget touches `HereMap`/`SearchEngine`/etc. Must run on the main isolate.
/// See the HERE SDK for Flutter Developer Guide's "Integrate the HERE SDK"
/// tutorial for the exact sequence this mirrors.
///
/// Deliberately tolerant of missing credentials (same posture as this app's
/// existing Firebase.initializeApp() try/catch in main.dev.dart/main.prod.dart)
/// — until HERE_ACCESS_KEY_ID/SECRET are supplied via --dart-define, the map
/// screen simply won't have a working HereMapController, rather than crashing
/// app boot entirely.
Future<void> initializeHereSdk() async {
  if (!AppConfig.hasHereSdkCredentials) {
    debugPrint('HERE SDK init skipped: HERE_ACCESS_KEY_ID/HERE_ACCESS_KEY_SECRET not supplied via --dart-define.');
    return;
  }

  // Needs to be called before accessing SDKOptions to load necessary libraries.
  SdkContext.init(IsolateOrigin.main);

  final authenticationMode = AuthenticationMode.withKeySecret(
    AppConfig.hereAccessKeyId,
    AppConfig.hereAccessKeySecret,
  );
  final sdkOptions = SDKOptions.withAuthenticationMode(authenticationMode);

  try {
    await SDKNativeEngine.makeSharedInstance(sdkOptions);
  } on InstantiationException catch (e) {
    debugPrint('HERE SDK failed to initialize: $e');
  }
}

/// Releases native HERE SDK resources. Not mandatory on app shutdown per the
/// Developer Guide, but cheap and good practice to call from the app root's
/// dispose() if it's ever converted to a StatefulWidget.
Future<void> disposeHereSdk() async {
  await SDKNativeEngine.sharedInstance?.dispose();
  SdkContext.release();
}
