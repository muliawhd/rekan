import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../auth/api_session.dart';

enum ApiFailureKind {
  authentication,
  sessionChanged,
  forbidden,
  validation,
  conflict,
  rateLimited,
  unavailable,
  network,
  protocol,
}

class ApiFailure implements Exception {
  const ApiFailure(this.kind, {this.status});
  final ApiFailureKind kind;
  final int? status;
  String get message => switch (kind) {
    ApiFailureKind.authentication => 'Sign in again to continue.',
    ApiFailureKind.sessionChanged => 'Session changed. Load the profile again.',
    ApiFailureKind.forbidden => 'Access denied.',
    ApiFailureKind.validation => 'The profile was rejected. Check its fields.',
    ApiFailureKind.conflict => 'Catalog data changed. Reload before retrying.',
    ApiFailureKind.rateLimited => 'Too many requests. Wait before retrying.',
    ApiFailureKind.unavailable => 'The service is temporarily unavailable.',
    ApiFailureKind.network =>
      'Could not reach the service. Check your connection.',
    ApiFailureKind.protocol => 'The service returned an unexpected response.',
  };
  @override
  String toString() => 'ApiFailure(${kind.name})';
}

enum ApiEndpoint {
  me('me'),
  universities('universities'),
  courses('courses'),
  skills('skills'),
  academicProfile('me/academic-profile');

  const ApiEndpoint(this.path);
  final String path;
}

class ApiResponse {
  const ApiResponse(this.status, this.body);
  final int status;
  final String body;
}

abstract interface class ApiTransport {
  Future<ApiResponse> send(
    String method,
    Uri uri,
    String token,
    Map<String, dynamic>? body, {
    bool requireEmpty = false,
  });
}

class IoApiTransport implements ApiTransport {
  @override
  Future<ApiResponse> send(
    String method,
    Uri uri,
    String token,
    Map<String, dynamic>? body, {
    bool requireEmpty = false,
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      return await (() async {
        final request = await client.openUrl(method, uri);
        request.followRedirects = false;
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
        if (requireEmpty) {
          request.headers.set('X-Re-Require-Empty-Profile', 'true');
        }
        if (body != null) {
          request.headers.contentType = ContentType.json;
          request.write(jsonEncode(body));
        }
        final response = await request.close();
        final bytes = <int>[];
        await for (final chunk in response) {
          bytes.addAll(chunk);
          if (bytes.length > 1024 * 1024) {
            throw const ApiFailure(ApiFailureKind.protocol);
          }
        }
        return ApiResponse(response.statusCode, utf8.decode(bytes));
      })().timeout(const Duration(seconds: 15));
    } finally {
      client.close(force: true);
    }
  }
}

class LaravelApi {
  LaravelApi({
    required String baseUrl,
    required this.sessions,
    ApiTransport? transport,
  }) : base = Uri.parse(baseUrl),
       _transport = transport ?? IoApiTransport() {
    final localDebug = kDebugMode && baseUrl == 'http://10.0.2.2:8000/api/v1';
    if ((!localDebug && base.scheme != 'https') ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment ||
        base.path != '/api/v1') {
      throw const FormatException(
        'Configure an HTTPS API root or the debug emulator API.',
      );
    }
  }
  final Uri base;
  final ApiSessionSource sessions;
  final ApiTransport _transport;
  Future<void>? _refreshing;

  void _checkSession(ApiSession original) {
    final now = sessions.current;
    if (now == null ||
        now.userId != original.userId ||
        now.generation != original.generation) {
      throw const ApiFailure(ApiFailureKind.sessionChanged);
    }
  }

  Future<void> _refresh(ApiSession original) async {
    _checkSession(original);
    final pending = _refreshing ??= Future<void>.sync(sessions.refresh)
        .timeout(const Duration(seconds: 15));
    try {
      await pending;
    } catch (_) {
      throw const ApiFailure(ApiFailureKind.authentication);
    } finally {
      if (identical(_refreshing, pending)) _refreshing = null;
    }
    _checkSession(original);
    if (sessions.current!.expired) {
      throw const ApiFailure(ApiFailureKind.authentication);
    }
  }

  Future<T> request<T>(
    ApiEndpoint endpoint,
    T Function(Map<String, dynamic>, String) decode, {
    Map<String, dynamic>? put,
    bool requireEmpty = false,
  }) => _request(
    endpoint,
    (data, user) => decode(data as Map<String, dynamic>, user),
    put: put,
    requireEmpty: requireEmpty,
  );

  Future<List<T>> getCatalog<T>(
    ApiEndpoint endpoint,
    T Function(Map<String, dynamic>) decode,
    Map<String, dynamic> query,
  ) => _request(
    endpoint,
    (data, _) => List<T>.unmodifiable(
      (data as List).map((item) => decode(item as Map<String, dynamic>)),
    ),
    query: query,
  );

  Future<T> _request<T>(
    ApiEndpoint endpoint,
    T Function(Object?, String) decode, {
    Map<String, dynamic>? put,
    bool requireEmpty = false,
    Map<String, dynamic>? query,
  }) async {
    final uri = Uri.parse('$base/${endpoint.path}')
        .replace(queryParameters: query);
    final original = sessions.current;
    if (original == null) throw const ApiFailure(ApiFailureKind.authentication);
    // Freeze the PUT body so a retry cannot send a caller-mutated payload.
    final body = put == null
        ? null
        : jsonDecode(jsonEncode(put)) as Map<String, dynamic>;
    var refreshed = false;
    if (original.expired) {
      await _refresh(original);
      refreshed = true;
    }
    for (var attempt = 0; attempt < 2; attempt++) {
      _checkSession(original);
      final sent = sessions.current!;
      ApiResponse response;
      try {
        response = await _transport.send(
          put == null ? 'GET' : 'PUT',
          uri,
          sent.accessToken,
          body,
          requireEmpty: requireEmpty,
        );
      } on ApiFailure {
        rethrow;
      } catch (_) {
        throw const ApiFailure(ApiFailureKind.network);
      }
      _checkSession(original);
      if (response.status == 401 && attempt == 0 && !refreshed) {
        // Another request/SDK auto-refresh may already have rotated the token.
        if (sessions.current!.accessToken == sent.accessToken ||
            sessions.current!.expired) {
          await _refresh(original);
        }
        refreshed = true;
        continue;
      }
      if (response.status != 200) {
        throw ApiFailure(switch (response.status) {
          401 => ApiFailureKind.authentication,
          403 => ApiFailureKind.forbidden,
          409 => ApiFailureKind.conflict,
          422 => ApiFailureKind.validation,
          429 => ApiFailureKind.rateLimited,
          >= 500 => ApiFailureKind.unavailable,
          _ => ApiFailureKind.protocol,
        }, status: response.status);
      }
      try {
        final envelope = jsonDecode(response.body) as Map<String, dynamic>;
        if (envelope['request_id'] is! String) throw const FormatException();
        return decode(envelope['data'], original.userId);
      } on ApiFailure {
        rethrow;
      } catch (_) {
        throw const ApiFailure(ApiFailureKind.protocol);
      }
    }
    throw const ApiFailure(ApiFailureKind.authentication);
  }

  Future<String> getIdentity() => request(ApiEndpoint.me, (data, userId) {
    if (data['id'] != userId) throw const ApiFailure(ApiFailureKind.protocol);
    return userId;
  });
}
