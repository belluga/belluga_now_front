import 'package:belluga_now/domain/repositories/courses_repository_contract.dart';
import 'package:belluga_now/infrastructure/services/laravel_backend/backend_contract.dart';
import 'package:get_it/get_it.dart';

final class FastTracksRepository extends CoursesRepositoryContract {
  @override
  BackendContract get backend => GetIt.I.get<BackendContract>();
}
