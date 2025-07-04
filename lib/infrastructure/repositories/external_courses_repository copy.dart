import 'package:flutter_laravel_backend_boilerplate/domain/repositories/my_courses_repository_contract.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/laravel_backend/backend_contract.dart';
import 'package:get_it/get_it.dart';

final class MyCoursesRepository
    extends MyCoursesRepositoryContract {

  BackendContract get backend => GetIt.I.get<BackendContract>();

}
