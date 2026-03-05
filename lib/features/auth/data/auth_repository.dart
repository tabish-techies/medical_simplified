import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/storage/token_storage.dart';
import 'auth_api.dart';
import 'package:medical_simplified/core/networking/api_client.dart'
    show SessionExpiredException;

class AuthRepository {
  AuthRepository(this._api, this._tokenStorage);

  final AuthApi _api;
  final TokenStorage _tokenStorage;

  // ----------------------------
  // OTP Handling
  // ----------------------------
  Future<void> sendOtp({required String phone}) async {
    final response = await _api.sendOtp(phone: phone);

    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to send OTP');
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
  required String phone,
  required String otp,
}) async {
  final response = await _api.verifyOtp(phone: phone, otp: otp);

  if (response.statusCode != 200) {
    throw Exception('Server error: ${response.statusCode}');
  }

  final Map<String, dynamic> body = jsonDecode(response.body);
  if (body['success'] != true) {
    throw Exception(body['message'] ?? 'OTP verification failed');
  }

  final data = body['data'];
  final accessToken = data['accessToken'];
  final refreshToken = data['refreshToken'];
  final user = data['user'] ?? {};

  // ✅ Save both tokens and user info securely
  await _tokenStorage.saveTokens(
    accessToken: accessToken,
    refreshToken: refreshToken,
  );
  await _tokenStorage.saveUser(user);
  print(user);
  return user;
}

  // ----------------------------
  // Auth Lifecycle
  // ----------------------------
  Future<bool> isLoggedIn() => _tokenStorage.hasTokens();

  Future<void> logout() => _tokenStorage.clearTokens();

  Future<void> registerUser(Map<String, dynamic> userData) async {
    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken == null) throw Exception('Access token not found.');

    final response = await _api.registerUser(
      userData: userData,
      accessToken: accessToken,
    );

    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to register user');
    }

    // ✅ Save updated user data locally
    final userDataResponse = body['data']; 
    if (userDataResponse != null) {
      await _tokenStorage.saveUser(userDataResponse);
      print('✅ [AuthRepo] User data updated after registration.');
    }
  }

  Future<void> logoutFromServer() async {
    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken == null) throw Exception('No access token found');

    try {
      final response = await _api.logout(accessToken: accessToken);
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] != true) {
          print('⚠️ [AuthRepo] Server logout unsuccessful: ${body['message']}');
        }
      }
    } catch (e) {
      print('⚠️ [AuthRepo] Server logout request failed: $e');
    } finally {
      await _tokenStorage.clearTokens();
      print('🚪 [AuthRepo] Local tokens cleared after logout.');
    }
  }

  // ----------------------------
  // Token Refresh
  // ----------------------------
  Future<bool> refreshTokens() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null) {
      print('❌ [AuthRepo] No refresh token found');
      return false;
    }

    try {
      final response = await _api.refreshToken(refreshToken: refreshToken);
      print('📥 [AuthRepo] Refresh response: ${response.statusCode}');

      if (response.statusCode == 401) {
        final body = _safeJsonDecode(response.body);
        final msg = (body['message'] ?? '').toString().toLowerCase();
        if (msg.contains('invalid refresh token') ||
            msg.contains('refresh token expired') ||
            msg.contains('refresh token has expired')) {
          print('🔒 [AuthRepo] Refresh token invalid/expired.');
          return false;
        }
      }

      if (response.statusCode != 200) {
        print('❌ [AuthRepo] Refresh failed (status ${response.statusCode})');
        return false;
      }

      final Map<String, dynamic> body = jsonDecode(response.body);
      if (body['success'] != true) {
        print('❌ [AuthRepo] Refresh response unsuccessful');
        return false;
      }

      final data = body['data'];
      final newAccessToken = data['accessToken'];
      final newRefreshToken = data['refreshToken'];

      if (newAccessToken == null || newRefreshToken == null) {
        print('❌ [AuthRepo] Missing tokens in refresh response');
        return false;
      }

      await _tokenStorage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );

      print('✅ [AuthRepo] Tokens refreshed successfully.');
      return true;
    } catch (e) {
      print('❌ [AuthRepo] Refresh request failed: $e');
      return false;
    }
  }

  // ----------------------------
  // Authenticated Greeting Test
  // ----------------------------
  Future<String> greet() async {
    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken == null) throw SessionExpiredException('Access token not found');

    final response = await _api.greet(accessToken);
    print('📥 [AuthRepo] greet() response: ${response.statusCode}');

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return body['message'] ?? response.body;
      } catch (_) {
        return response.body;
      }
    }

    if (response.statusCode == 401) {
      print('⚠️ [AuthRepo] 401 even after refresh attempt — retrying once...');
      final retryAccess = await _tokenStorage.readAccessToken();
      if (retryAccess != null) {
        final retryResponse = await _api.greet(retryAccess);
        if (retryResponse.statusCode == 200) {
          try {
            final Map<String, dynamic> body = jsonDecode(retryResponse.body);
            return body['message'] ?? retryResponse.body;
          } catch (_) {
            return retryResponse.body;
          }
        }
      }
      throw SessionExpiredException('Session invalid after refresh');
    }

    throw Exception('Greet failed with status: ${response.statusCode}');
  }

  // ----------------------------
  // Safe JSON decode helper
  // ----------------------------
  Map<String, dynamic> _safeJsonDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return {};
    }
  }

// ----------------------------
// Firebase OTP Verification
// ----------------------------
Future<Map<String, dynamic>> verifyFirebaseToken({
  required String firebaseToken,
}) async {
  final response = await _api.verifyFirebaseToken(
    firebaseToken: firebaseToken,
  );

  if (response.statusCode != 200) {
    throw Exception('Authentication failed');
  }

  final Map<String, dynamic> body = jsonDecode(response.body);

  if (body['success'] != true) {
    throw Exception(body['message'] ?? 'Firebase verification failed');
  }

  final data = body['data'];

  await _tokenStorage.saveTokens(
    accessToken: data['accessToken'],
    refreshToken: data['refreshToken'],
  );

  await _tokenStorage.saveUser(data['user']);

  print(data['user']);

  return data['user'];
}


}
