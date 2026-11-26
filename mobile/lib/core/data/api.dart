import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

// 10.0.2.2 is the host machine from the Android emulator.
// Point a phone or another server at it: --dart-define=API_URL=https://...
const apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://10.0.2.2:8080',
);

/// The server said no (`reason` is its `error` code), or it couldn't be
/// reached (`status` 0, reason `offline`).
class ApiError implements Exception {
  const ApiError(this.status, this.reason, [this.body = const {}]);

  final int status;
  final String reason;
  final Map<String, Object?> body;

  @override
  String toString() => 'ApiError($status, $reason)';
}

class Api {
  Api({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? token;

  Future<Object?> get(String path) => _send('GET', path);

  Future<Object?> post(String path, [Object? body]) =>
      _send('POST', path, body);

  Future<Object?> delete(String path) => _send('DELETE', path);

  Future<Object?> _send(String method, String path, [Object? body]) async {
    final request = http.Request(method, Uri.parse('$apiUrl$path'));
    if (token case final t?) request.headers['Authorization'] = 'Bearer $t';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final http.Response res;
    try {
      res = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 15)),
      );
    } on SocketException {
      throw const ApiError(0, 'offline');
    } on TimeoutException {
      throw const ApiError(0, 'offline');
    } on http.ClientException {
      throw const ApiError(0, 'offline');
    }
    final json = res.body.isEmpty
        ? null
        : jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 400) {
      final map = json is Map<String, Object?> ? json : <String, Object?>{};
      throw ApiError(
        res.statusCode,
        map['error'] as String? ?? 'internal',
        map,
      );
    }
    return json;
  }
}
