import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central API service with consistent error handling
class ApiService {
  static const String _tokenKey = 'jwt_token';
  static const Duration _requestTimeout = Duration(seconds: 10);
  static const Duration _uploadTimeout = Duration(seconds: 25);

  // ─── Token Storage ──────────────────────────────────────────────────────────

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // ─── HTTP Helpers ───────────────────────────────────────────────────────────

  static Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (auth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Map<String, dynamic> _parseResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return body;
      } else {
        throw ApiException(
            body['message'] ?? 'Server error', response.statusCode);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
          'Failed to parse server response', response.statusCode);
    }
  }

  static Future<Map<String, dynamic>> get(String url,
      {bool auth = false}) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: await _headers(auth: auth))
          .timeout(_requestTimeout);
      return _parseResponse(response);
    } on TimeoutException {
      throw ApiException('Connection unavailable', 0);
    } on SocketException {
      throw ApiException('Connection unavailable', 0);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e', 0);
    }
  }

  static Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: await _headers(auth: auth),
            body: jsonEncode(body),
          )
          .timeout(_requestTimeout);
      return _parseResponse(response);
    } on TimeoutException {
      throw ApiException('Connection unavailable', 0);
    } on SocketException {
      throw ApiException('Connection unavailable', 0);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e', 0);
    }
  }

  static Future<Map<String, dynamic>> put(
    String url,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse(url),
            headers: await _headers(auth: auth),
            body: jsonEncode(body),
          )
          .timeout(_requestTimeout);
      return _parseResponse(response);
    } on TimeoutException {
      throw ApiException('Connection unavailable', 0);
    } on SocketException {
      throw ApiException('Connection unavailable', 0);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e', 0);
    }
  }

  static Future<Map<String, dynamic>> delete(String url,
      {bool auth = false}) async {
    try {
      final response = await http
          .delete(Uri.parse(url), headers: await _headers(auth: auth))
          .timeout(_requestTimeout);
      return _parseResponse(response);
    } on TimeoutException {
      throw ApiException('Connection unavailable', 0);
    } on SocketException {
      throw ApiException('Connection unavailable', 0);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e', 0);
    }
  }

  /// Multipart POST for file uploads
  static Future<Map<String, dynamic>> postMultipart(
    String url, {
    required Map<String, String> fields,
    List<int>? fileBytes,
    String? fileName,
    String fileField = 'image',
    bool auth = false,
  }) async {
    try {
      final token = auth ? await getToken() : null;
      final request = http.MultipartRequest('POST', Uri.parse(url));

      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.fields.addAll(fields);

      if (fileBytes != null && fileName != null) {
        request.files.add(http.MultipartFile.fromBytes(
          fileField,
          fileBytes,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      final streamedResponse = await request.send().timeout(_uploadTimeout);
      final response = await http.Response.fromStream(streamedResponse);
      return _parseResponse(response);
    } on TimeoutException {
      throw ApiException('Connection unavailable', 0);
    } on SocketException {
      throw ApiException('Connection unavailable', 0);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Upload failed: $e', 0);
    }
  }

  /// Multipart PUT for file uploads
  static Future<Map<String, dynamic>> putMultipart(
    String url, {
    required Map<String, String> fields,
    List<int>? fileBytes,
    String? fileName,
    String fileField = 'image',
    bool auth = false,
  }) async {
    try {
      final token = auth ? await getToken() : null;
      final request = http.MultipartRequest('PUT', Uri.parse(url));

      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.fields.addAll(fields);

      if (fileBytes != null && fileName != null) {
        request.files.add(http.MultipartFile.fromBytes(
          fileField,
          fileBytes,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      final streamedResponse = await request.send().timeout(_uploadTimeout);
      final response = await http.Response.fromStream(streamedResponse);
      return _parseResponse(response);
    } on TimeoutException {
      throw ApiException('Connection unavailable', 0);
    } on SocketException {
      throw ApiException('Connection unavailable', 0);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Upload failed: $e', 0);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  bool get isNetworkError => statusCode == 0;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
