import 'package:flutter_laravel_backend_boilerplate/domain/repositories/courses_repository_contract.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/laravel_backend/backend_contract.dart';
import 'package:get_it/get_it.dart';

final class CoursesRepository
    extends CoursesRepositoryContract {

  BackendContract get backend => GetIt.I.get<BackendContract>();

}
