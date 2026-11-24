import '../../../core/network/laravel_api.dart';
import '../domain/academic_onboarding_completion.dart';

/// Read-only catalogs using the same authenticated transport as profile requests.
class AcademicCatalogRepository {
  AcademicCatalogRepository(this.api);
  final LaravelApi api;

  Future<List<UniversityCatalogItem>> universities({
    String q = '',
    List<String>? ids,
  }) => _read(
    ApiEndpoint.universities,
    (json) =>
        UniversityCatalogItem(id: _id(json['id']), name: _text(json['name'])),
    q: q,
    ids: ids,
  );

  Future<List<CourseCatalogItem>> courses({
    String q = '',
    String? universityId,
    List<String>? ids,
  }) => _read(
    ApiEndpoint.courses,
    (json) {
      if (!json.containsKey('university_id')) throw const FormatException();
      return CourseCatalogItem(
        id: _id(json['id']),
        code: _text(json['code']),
        name: _text(json['name']),
        universityId: json['university_id'] == null
            ? null
            : _id(json['university_id']),
      );
    },
    q: q,
    ids: ids,
    universityId: universityId,
  );

  Future<List<SkillCatalogItem>> skills({String q = '', List<String>? ids}) =>
      _read(
        ApiEndpoint.skills,
        (json) => SkillCatalogItem(
          id: _id(json['id']),
          normalizedName: _text(json['normalized_name']),
        ),
        q: q,
        ids: ids,
      );

  Future<List<T>> _read<T>(
    ApiEndpoint endpoint,
    T Function(Map<String, dynamic>) decode, {
    required String q,
    List<String>? ids,
    String? universityId,
  }) async {
    if (q.runes.length > 100) throw const ApiFailure(ApiFailureKind.validation);
    final normalized = ids?.map(_id).toSet().toList();
    if (normalized != null && normalized.isEmpty) return [];
    final session = api.sessions.current;
    final result = <T>[];
    // The response limit is 50 even when the endpoint accepts 100 IDs.
    for (var offset = 0; offset < (normalized?.length ?? 1); offset += 50) {
      if (api.sessions.current?.userId != session?.userId ||
          api.sessions.current?.generation != session?.generation) {
        throw const ApiFailure(ApiFailureKind.sessionChanged);
      }
      result.addAll(
        await api.getCatalog(endpoint, decode, {
          'limit': '50',
          if (q.trim().isNotEmpty) 'q': q.trim(),
          if (universityId != null) 'university_id': _id(universityId),
          if (normalized != null)
            'ids[]': normalized.skip(offset).take(50).toList(),
        }),
      );
    }
    return List.unmodifiable(result);
  }

  static String _id(Object? value) {
    if (value is! String || !AcademicOnboardingValidation.isValidUuid(value)) {
      throw const FormatException();
    }
    return value.toLowerCase();
  }

  static String _text(Object? value) {
    if (value is! String || value.trim().isEmpty) throw const FormatException();
    return value;
  }
}
