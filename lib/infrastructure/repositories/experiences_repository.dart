import 'package:belluga_now/domain/experiences/experience_model.dart';
import 'package:belluga_now/domain/repositories/experiences_repository_contract.dart';
import 'package:belluga_now/infrastructure/services/dal/datasources/mock_experiences_database.dart';

class ExperiencesRepository extends ExperiencesRepositoryContract {
  ExperiencesRepository({
    MockExperiencesDatabase? database,
  }) : _database = database ?? const MockExperiencesDatabase();

  final MockExperiencesDatabase _database;

  @override
  Future<List<ExperienceModel>> fetchExperiences() async {
    return _database.experiences;
  }

  @override
  Future<ExperienceModel?> fetchById(String id) async {
    return _database.findById(id);
  }
}
