import 'package:flutter_test/flutter_test.dart';
import 'package:re_mobile/features/auth_validation/development_api.dart';

void main() {
  test('development harness rejects other destinations for bearer tokens', () {
    for (final url in [
      'https://example.com/api/v1',
      'http://0.0.0.0:8000/api/v1',
      'http://10.0.2.2:8000/api/v1?redirect=other',
    ]) {
      expect(() => DevelopmentApi(url), throwsFormatException);
    }
    expect(DevelopmentApi('http://10.0.2.2:8000/api/v1'), isNotNull);
  });
  test('identity check requires successful response and matching UUID', () {
    expect(
      DevelopmentApi.matchesIdentity(200, {
        'data': {'id': 'one'},
      }, 'one'),
      isTrue,
    );
    expect(
      DevelopmentApi.matchesIdentity(200, {
        'data': {'id': 'two'},
      }, 'one'),
      isFalse,
    );
    expect(
      DevelopmentApi.matchesIdentity(401, {
        'data': {'id': 'one'},
      }, 'one'),
      isFalse,
    );
    expect(DevelopmentApi.matchesIdentity(200, {}, 'one'), isFalse);
  });
}
