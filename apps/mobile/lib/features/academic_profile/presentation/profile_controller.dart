import 'package:flutter/foundation.dart';

import '../../../core/network/laravel_api.dart';
import '../data/academic_profile.dart';
import '../data/academic_profile_repository.dart';

enum ProfileStatus { idle, loading, empty, success, error }

class ProfileController extends ChangeNotifier {
  ProfileController(this.repository);
  final AcademicProfileRepository repository;
  ProfileStatus status = ProfileStatus.idle;
  AcademicProfile? profile;
  ApiFailure? failure;
  int _version = 0;
  bool _disposed = false;
  Future<void> load() => _run(repository.get);
  Future<void> save(AcademicProfileInput input) =>
      _run(() => repository.put(input));
  Future<void> _run(Future<AcademicProfile> Function() action) async {
    final version = ++_version;
    status = ProfileStatus.loading;
    failure = null;
    profile = null;
    notifyListeners();
    try {
      final result = await action();
      if (_disposed || version != _version) return;
      profile = result;
      status = result.input.isEmpty
          ? ProfileStatus.empty
          : ProfileStatus.success;
    } catch (error) {
      if (_disposed || version != _version) return;
      failure = error is ApiFailure
          ? error
          : const ApiFailure(ApiFailureKind.protocol);
      status = ProfileStatus.error;
    }
    if (!_disposed && version == _version) notifyListeners();
  }

  void clear() {
    _version++;
    profile = null;
    failure = null;
    status = ProfileStatus.idle;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _version++;
    super.dispose();
  }
}
