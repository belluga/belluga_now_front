import 'package:belluga_now/domain/repositories/external_courses_repository_contract.dart';
import 'package:belluga_now/infrastructure/services/laravel_backend/backend_contract.dart';
import 'package:get_it/get_it.dart';

final class ExternalCoursesRepository
    extends ExternalCoursesRepositoryContract {
  @override
  BackendContract get backend => GetIt.I.get<BackendContract>();
}
