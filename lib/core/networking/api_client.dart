import 'dart:convert';
import 'dart:async';
import 'dart:io'; // ✅ For SocketException
import 'package:http/http.dart' as http;
import '../storage/token_storage.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/auth_api.dart';

/// Global session-expiry exception — caught by UI
class SessionExpiredException implements Exception {
  final String message;
  SessionExpiredException([this.message = 'Session expired. Please log in again.']);
  @override
  String toString() => message;
}

class ApiClient {
  final String baseUrl;
  final TokenStorage _tokenStorage;
  late final AuthRepository _authRepository;

  /// Global logout callback (set in main.dart)
  static Future<void> Function()? onSessionExpired;

  bool _isRefreshing = false;
  Completer<void>? _refreshCompleter;

  ApiClient({required this.baseUrl, required TokenStorage tokenStorage})
      : _tokenStorage = tokenStorage {
    _authRepository = AuthRepository(AuthApi(this), _tokenStorage);
  }

  // ----------------------------
  // Generic POST
  // ----------------------------
  Future<http.Response> post(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return _sendWithRetry(
      (hdrs) => http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: hdrs,
        body: body is Map ? jsonEncode(body) : body,
      ),
      endpoint: endpoint,
      additionalHeaders: headers,
    );
  }

  // ----------------------------
  // Generic GET
  // ----------------------------
  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    return _sendWithRetry(
      (hdrs) => http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: hdrs,
      ),
      endpoint: endpoint,
      additionalHeaders: headers,
    );
  }

  // ----------------------------
  // Retry / Refresh / Logout Logic
  // ----------------------------
  Future<http.Response> _sendWithRetry(
    Future<http.Response> Function(Map<String, String>) requestFn, {
    bool retrying = false,
    String? endpoint,
    Map<String, String>? additionalHeaders,
  }) async {
    // Skip auth header for refresh endpoint
    if (endpoint != null && endpoint.contains('/api/auth/refresh')) {
      final refreshToken = await _tokenStorage.readRefreshToken();
      if (refreshToken == null) {
        throw SessionExpiredException('No refresh token available');
      }
      return await requestFn({
        'Content-Type': 'application/json',
        'Refresh-Token': refreshToken,
        ...?additionalHeaders,
      });
    }

    // Build headers with access token
    final accessToken = await _tokenStorage.readAccessToken();
    final defaultHeaders = {
      'Content-Type': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      ...?additionalHeaders,
    };

    print('🌐 [ApiClient] → Request: $endpoint');
    
    http.Response response;
    try {
      response = await requestFn(defaultHeaders);
    } on SocketException catch (e) {
      if (e.osError?.errorCode == 111) {
        throw Exception('Connection refused. Is the server running?');
      } else if (e.osError?.errorCode == 101 || e.message.contains('Network is unreachable')) {
         throw Exception('Network unreachable. Check your internet connection.');
      }
      throw Exception('Network error: ${e.message}');
    } on http.ClientException catch (e) {
      throw Exception('Client error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }

    print('📥 [ApiClient] ← Response: ${response.statusCode} ($endpoint)');

    // ----------------------------
    // Handle Unauthorized (401)
    // ----------------------------
    if (response.statusCode == 401 && !retrying) {
      final body = _safeJsonDecode(response.body);
      final msg = (body['message'] ?? '').toString().toLowerCase();

      // Refresh token invalid → logout
      if (msg.contains('invalid refresh token') ||
          msg.contains('refresh token expired') ||
          msg.contains('refresh token has expired')) {
        await _handleSessionExpired();
        throw SessionExpiredException('Refresh token expired');
      }

      // Access token expired → refresh
      if (msg.contains('access token has expired') ||
          msg.contains('access token expired') ||
          msg.contains('jwt expired')) {
        if (_refreshCompleter != null) {
          await _refreshCompleter!.future; // wait for ongoing refresh
        } else {
          _refreshCompleter = Completer<void>();
          _isRefreshing = true;
          try {
            final refreshed = await _authRepository.refreshTokens();
            _refreshCompleter?.complete();

            if (!refreshed) {
              await _handleSessionExpired();
              throw SessionExpiredException('Token refresh failed');
            }
          } catch (e) {
            if (!(_refreshCompleter?.isCompleted ?? true)) {
              _refreshCompleter?.complete();
            }
            await _handleSessionExpired();
            throw SessionExpiredException('Token refresh failed');
          } finally {
            _isRefreshing = false;
            _refreshCompleter = null;
          }
        }

        // Ensure token is saved before retry
        await Future.delayed(const Duration(milliseconds: 150));
        final newAccessToken = await _tokenStorage.readAccessToken();
        if (newAccessToken == null) {
          throw SessionExpiredException('No token after refresh');
        }

        final retryHeaders = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $newAccessToken',
          ...?additionalHeaders,
        };

        print('🔁 [ApiClient] Retrying request after refresh...');
        final retryResponse = await requestFn(retryHeaders);
        print('📥 [ApiClient] ← Retry Response: ${retryResponse.statusCode} ($endpoint)');
        return retryResponse;
      }

      await _handleSessionExpired();
      throw SessionExpiredException(msg);
    }

    return response;
  }

  // ----------------------------
  // Shared logout handler
  // ----------------------------
  Future<void> _handleSessionExpired() async {
    await _tokenStorage.clearTokens();
    print('🚪 [ApiClient] Session expired → tokens cleared');

    if (onSessionExpired != null) {
      await onSessionExpired!();
    } else {
      print('⚠️ [ApiClient] onSessionExpired callback not set.');
    }
  }

  Map<String, dynamic> _safeJsonDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return {};
    }
  }
}
