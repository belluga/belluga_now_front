import 'package:unifast_portal/infrastructure/services/dal/dto/course/category_dto.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/course/course_item_summary_dto.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/course/course_item_dto.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/external_course_dto.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/user_dto.dart';

abstract class BackendContract {
  Future<(UserDTO, String)> loginWithEmailPassword(
    String email,
    String password,
  );
  Future<void> logout();
  Future<UserDTO> loginCheck();
  Future<List<ExternalCourseDTO>> getExternalCourses();
  Future<List<CourseItemSummaryDTO>> getMyCourses();
  Future<List<CourseItemSummaryDTO>> getUnifastTracks();
  Future<List<CourseItemSummaryDTO>> getLastFastTrackCourses();
  Future<CourseItemDetailsDTO> courseItemGetDetails(String courseId);
  Future<List<CategoryDTO>> getFastTracksCategories();
}
