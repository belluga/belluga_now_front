import 'package:belluga_now/infrastructure/services/dal/dto/app_data_dto.dart';

abstract class AppDataBackendContract {
  Future<AppDataDTO> fetch();
}
