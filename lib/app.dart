import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';
import 'features/auth/presentation/splash/splash_screen.dart';
import 'core/storage/token_storage.dart';

class MyApp extends StatelessWidget {
  final TokenStorage tokenStorage;
  final GlobalKey<NavigatorState> navigatorKey;

  const MyApp({super.key, required this.tokenStorage, required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medical Simplified',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: UpgradeAlert(
        upgrader: Upgrader(
          durationUntilAlertAgain: const Duration(minutes: 5), // Remind frequently if not blocking
          debugLogging: true, // Helpful for debug
        ),
        showIgnore: false,
        showLater: false, // Force update behavior
        showReleaseNotes: true,
        dialogStyle: UpgradeDialogStyle.cupertino, // Often looks better
        child: const SplashScreen(),
      ),
    );
  }
}
