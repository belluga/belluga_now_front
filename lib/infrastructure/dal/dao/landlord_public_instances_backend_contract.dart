import 'package:belluga_now/infrastructure/dal/dto/app_data_dto.dart';

abstract class LandlordPublicInstancesBackendContract {
  Future<List<AppDataDTO>> fetchFeaturedInstanceEnvironments({
    required String landlordOrigin,
  });
}
