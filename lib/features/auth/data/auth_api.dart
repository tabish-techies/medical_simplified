import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/networking/api_client.dart';

class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  Future<http.Response> sendOtp({required String phone}) {
    return _client.post(
      '/api/otp/send',
      body: jsonEncode({'phone': phone}),
    );
  }

  Future<http.Response> verifyOtp({
    required String phone,
    required String otp,
  }) {
    return _client.post(
      '/api/otp/verify',
      body: jsonEncode({'phone': phone, 'otp': otp}),
    );
  }
    Future<http.Response> registerUser({
    required Map<String, dynamic> userData,
    required String accessToken,
  }) {
    return _client.post(
      '/api/user/register',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(userData),
    );
  }
  Future<http.Response> logout({required String accessToken}) {
  return _client.post(
    '/api/auth/logout',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    },
  );
}
Future<http.Response> refreshToken({required String refreshToken}) {
  return _client.post(
    '/api/auth/refresh',
    headers: {
      'Content-Type': 'application/json',
      'Refresh-Token': refreshToken,
    },
  );
}

// Example of an authenticated request
Future<http.Response> greet(String accessToken) {
  return _client.post(
    '/api/otp/greet',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    },
  );
}
Future<http.Response> verifyFirebaseToken({
  required String firebaseToken,
}) {
  return _client.post(
    '/api/otp/verify',
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'firebaseToken': firebaseToken,
    }),
  );
}



}
