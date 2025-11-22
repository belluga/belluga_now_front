import 'package:belluga_now/application/application_mobile_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/user/user_belluga.dart';
import 'package:belluga_now/infrastructure/repositories/auth_repository.dart';
import 'package:belluga_now/infrastructure/services/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:belluga_now/infrastructure/services/dal/dao/local/app_data_local_info_source/app_data_local_info_source.dart';
import 'package:belluga_now/infrastructure/services/dal/dao/mock_backend/mock_app_data_backend.dart';
import 'package:belluga_now/infrastructure/services/dal/dao/mock_backend/mock_backend.dart';

class Application extends ApplicationMobileContract {
  Application({super.key});

  @override
  AuthRepositoryContract<UserBelluga> initAuthRepository() {
    return AuthRepository();
  }

  @override
  BackendContract initBackendRepository() => MockBackend();

  @override
  AppDataRepository initAppDataRepository() {
    return AppDataRepository(
      localInfoSource: AppDataLocalInfoSource(),
      backend: MockAppDataBackend(),
    );
  }
}
