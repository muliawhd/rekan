import '../../../core/network/laravel_api.dart';
import 'academic_profile.dart';

class AcademicProfileRepository {
  AcademicProfileRepository(this.api);
  final LaravelApi api;
  AcademicProfile _decode(Map<String, dynamic> json, String userId) {
    final profile = AcademicProfile.fromJson(json);
    if (profile.userId != userId) {
      throw const ApiFailure(ApiFailureKind.protocol);
    }
    return profile;
  }

  Future<AcademicProfile> get() =>
      api.request(ApiEndpoint.academicProfile, _decode);
  Future<AcademicProfile> put(
    AcademicProfileInput input, {
    bool requireEmpty = false,
  }) => api.request(
    ApiEndpoint.academicProfile,
    _decode,
    put: input.toJson(),
    requireEmpty: requireEmpty,
  );
}
