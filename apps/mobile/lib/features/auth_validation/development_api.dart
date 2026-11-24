import 'dart:convert';
import 'dart:io';

/// Debug harness: never forwards a bearer token to arbitrary configured hosts.
class DevelopmentApi {
  DevelopmentApi(String baseUrl) : base = Uri.parse(baseUrl) {
    if (base.toString() != 'http://10.0.2.2:8000/api/v1') {
      throw const FormatException('Use the Android emulator development API.');
    }
  }

  final Uri base;

  Future<(int, Map<String, dynamic>)> get(String path, {String? token}) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final request = await client.getUrl(Uri.parse('$base/$path'));
      request.followRedirects = false;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (token != null) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );
      final body = await utf8.decoder
          .bind(response)
          .join()
          .timeout(const Duration(seconds: 10));
      final decoded = jsonDecode(body);
      return (
        response.statusCode,
        decoded is Map<String, dynamic> ? decoded : <String, dynamic>{},
      );
    } finally {
      client.close(force: true);
    }
  }

  static bool matchesIdentity(
    int status,
    Map<String, dynamic> body,
    String uuid,
  ) => status == 200 && body['data'] is Map && body['data']['id'] == uuid;

  Future<bool> checkGuestBoundary() async {
    final health = await get('health');
    final missing = await get('me');
    final invalid = await get('me', token: 'invalid-test-token');
    return health.$1 == 200 &&
        health.$2['status'] == 'ok' &&
        missing.$1 == 401 &&
        invalid.$1 == 401 &&
        missing.$2['error']?['code'] == 'UNAUTHENTICATED' &&
        invalid.$2['error']?['code'] == 'UNAUTHENTICATED';
  }
}
