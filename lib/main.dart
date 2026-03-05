import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // ✅ ADD
import 'package:medical_simplified/config/api_config.dart';
import 'core/networking/api_client.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/auth_api.dart';
import 'features/auth/presentation/login/login_screen.dart';
import 'app.dart';
import 'package:firebase_core/firebase_core.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
    // Continue anyway to show error screen if possible, or retry
  }

  // ✅ INITIALIZE FIREBASE
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  final tokenStorage = TokenStorage();

  // ✅ Global auto logout if refresh token expires
  ApiClient.onSessionExpired = () async {
    await tokenStorage.clearTokens();
    print('🗑️ Tokens cleared from secure storage');

    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please log in again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          authRepository: AuthRepository(
            AuthApi(ApiClient(baseUrl: '${ApiConfig.baseUrl}', tokenStorage: tokenStorage)),
            tokenStorage,
          ),
        ),
      ),
      (route) => false,
    );

    print('🚪 Navigated to LoginScreen due to session expiry');
  };

  runApp(MyApp(tokenStorage: tokenStorage, navigatorKey: navigatorKey));
}
