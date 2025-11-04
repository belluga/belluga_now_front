import 'package:belluga_now/domain/experiences/experience_model.dart';

abstract class ExperiencesRepositoryContract {
  Future<List<ExperienceModel>> fetchExperiences();
  Future<ExperienceModel?> fetchById(String id);
}
