import 'package:belluga_now/application/application_web_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/user/user_belluga.dart';
import 'package:belluga_now/infrastructure/repositories/auth_repository.dart';
import 'package:belluga_now/infrastructure/services/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/services/dal/dao/mock_backend/mock_backend.dart';

class Application extends ApplicationWebContract {
  Application({super.key});

  @override
  AuthRepositoryContract<UserBelluga> initAuthRepository() {
    return AuthRepository();
  }

  @override
  BackendContract initBackendRepository() => MockBackend();
}
