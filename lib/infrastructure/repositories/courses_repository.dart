import 'package:unifast_portal/domain/repositories/courses_repository_contract.dart';
import 'package:unifast_portal/infrastructure/services/laravel_backend/backend_contract.dart';
import 'package:get_it/get_it.dart';

final class CoursesRepository extends CoursesRepositoryContract {
  BackendContract get backend => GetIt.I.get<BackendContract>();
}
