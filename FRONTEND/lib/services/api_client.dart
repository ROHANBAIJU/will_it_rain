import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Central API client that injects Authorization header when token exists.
class ApiClient {
  ApiClient._internal();
  static final ApiClient instance = ApiClient._internal();

  final _storage = const FlutterSecureStorage();
  final String baseUrl = 'https://will-it-rain-3ogz.onrender.com';

  Future<Map<String, String>> _defaultHeaders() async {
    final token = await _storage.read(key: 'access_token');
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<http.Response> get(String path, {Map<String, String>? extraHeaders}) async {
    final headers = await _defaultHeaders();
    if (extraHeaders != null) headers.addAll(extraHeaders);
    final uri = Uri.parse('$baseUrl$path');
    return http.get(uri, headers: headers);
  }

  /// GET and decode JSON, throwing an exception for non-200 responses.
  Future<dynamic> getJson(String path, {Map<String, String>? extraHeaders}) async {
    final res = await get(path, extraHeaders: extraHeaders);
    final parsed = _handleResponse(res);
    try {
      // Log the JSON response only in debug mode so production logs stay clean
      if (kDebugMode) debugPrint('API GET $path response: ${jsonEncode(parsed)}');
    } catch (_) {
      if (kDebugMode) debugPrint('API GET $path response: (unserializable) $parsed');
    }
    return parsed;
  }

  Future<http.Response> post(String path, {Object? body, Map<String, String>? extraHeaders}) async {
    final headers = await _defaultHeaders();
    if (extraHeaders != null) headers.addAll(extraHeaders);
    final uri = Uri.parse('$baseUrl$path');
    return http.post(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
  }

  /// POST a JSON body and decode JSON response, throwing on non-200.
  Future<dynamic> postJson(String path, {Object? body, Map<String, String>? extraHeaders}) async {
    final res = await post(path, body: body, extraHeaders: extraHeaders);
    final parsed = _handleResponse(res);
    try {
      if (kDebugMode) debugPrint('API POST $path response: ${jsonEncode(parsed)}');
    } catch (_) {
      if (kDebugMode) debugPrint('API POST $path response: (unserializable) $parsed');
    }
    return parsed;
  }

  dynamic _handleResponse(http.Response res) {
    final status = res.statusCode;
    if (status >= 200 && status < 300) {
      return parseJson(res);
    }

    // try to parse error message
    try {
      final json = jsonDecode(res.body);
      if (json is Map<String, dynamic>) {
        if (json.containsKey('detail')) throw Exception(json['detail'].toString());
        if (json.containsKey('error')) throw Exception(json['error'].toString());
        if (json.containsKey('message')) throw Exception(json['message'].toString());
      }
    } catch (_) {}

    throw Exception('Request failed: ${res.statusCode} ${res.body}');
  }

  // helper to parse JSON responses
  dynamic parseJson(http.Response res) {
    try {
      return jsonDecode(res.body);
    } catch (_) {
      return null;
    }
  }
}
