import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/storage/hive_boxes.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.init(appFlavor: AppFlavor.dev);
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // No platform Firebase config present yet — push notifications stay
    // unavailable until real config files are added; the rest of the app
    // should still boot.
    debugPrint('Firebase init skipped: $e');
  }
  await HiveBoxes.init();

  runApp(const ProviderScope(child: VisorRouteApp()));
}

class VisorRouteApp extends ConsumerWidget {
  const VisorRouteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'VisorRoute (Dev)',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
