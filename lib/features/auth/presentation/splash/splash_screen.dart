import 'package:flutter/material.dart';
import 'package:medical_simplified/config/api_config.dart';
import '../../../../core/networking/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../auth/data/auth_api.dart';
import '../../../auth/data/auth_repository.dart';
import '../home/main_screen.dart';
import '../login/login_screen.dart';
import '../registration/registration_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final AuthRepository _authRepository;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  void _setup() {
    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(baseUrl: '${ApiConfig.baseUrl}', tokenStorage: tokenStorage);
    final authApi = AuthApi(apiClient);
    _authRepository = AuthRepository(authApi, tokenStorage);

    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(seconds: 2)); // splash timer

    final isLoggedIn = await _authRepository.isLoggedIn();
    final storedUser = await TokenStorage().readUser(); // ✅ check user data also
    if (!mounted) return;

    if (isLoggedIn && storedUser != null) {
      final isRegCompleted = storedUser['isRegCompleted'] == 1;

      if (isRegCompleted) {
        // ✅ Registered → go to home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainScreen(authRepository: _authRepository)),
        );
      } else {
        // ⚠️ Logged in but not registered → go to registration
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => RegistrationScreen(authRepository: _authRepository)),
        );
      }
    } else {
      // ⛔ No valid tokens or user → go to login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen(authRepository: _authRepository)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/medical_Simplified_logo.png',
              width: 200, // Adjust size as needed
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            const Text(
              'Medical Simplified',
              style: TextStyle(color: Color.fromARGB(255, 48, 95, 154), fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
