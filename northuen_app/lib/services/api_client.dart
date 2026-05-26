import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? token;

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> get(String path) async => _handle(await _client.get(_uri(path), headers: _headers));

  Future<dynamic> post(String path, Map<String, dynamic> body) async => _handle(await _client.post(_uri(path), headers: _headers, body: jsonEncode(body)));

  Future<dynamic> patch(String path, Map<String, dynamic> body) async => _handle(await _client.patch(_uri(path), headers: _headers, body: jsonEncode(body)));

  Future<dynamic> put(String path, Map<String, dynamic> body) async => _handle(await _client.put(_uri(path), headers: _headers, body: jsonEncode(body)));

  Future<void> delete(String path) async {
    await _handle(await _client.delete(_uri(path), headers: _headers));
  }

  dynamic _handle(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    if (response.body.isNotEmpty) {
      final json = jsonDecode(response.body);
      throw ApiException(
        json['message'] ?? 'Request failed',
        statusCode: response.statusCode,
      );
    }
    throw ApiException(
      'Request failed with ${response.statusCode}',
      statusCode: response.statusCode,
    );
  }
}
