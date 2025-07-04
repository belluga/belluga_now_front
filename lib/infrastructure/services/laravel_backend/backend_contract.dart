import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/course/course_dto.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/external_courses_summary_dto.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/my_courses_summary_dto.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/user_dto.dart';

abstract class BackendContract {
  Future<(UserDTO, String)> loginWithEmailPassword(
    String email,
    String password,
  );
  Future<void> logout();
  Future<UserDTO> loginCheck();
  Future<ExternalCoursesSummaryDTO> externalCoursesGetDashboardSummary();
  Future<MyCoursesSummaryDTO> myCoursesGetDashboardSummary();
  Future<CourseDTO> courseGetDetails(String courseId);
}
