import 'package:belluga_now/application/application_mobile_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/user/user_belluga.dart';
import 'package:belluga_now/infrastructure/repositories/auth_repository.dart';
import 'package:belluga_now/infrastructure/services/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/services/dal/dao/mock_backend/mock_backend.dart';

class Application extends ApplicationMobileContract {
  Application({super.key});

  @override
  AuthRepositoryContract<UserBelluga> initAuthRepository() {
    final _respository = AuthRepository();
    _respository.init();
    return _respository;
  }

  @override
  BackendContract initBackendRepository() => MockBackend();
}
