import 'package:unifast_portal/application/application_web_contract.dart';
import 'package:unifast_portal/domain/repositories/auth_repository_contract.dart';
import 'package:unifast_portal/domain/user/user_belluga.dart';
import 'package:unifast_portal/infrastructure/repositories/auth_repository.dart';
import 'package:unifast_portal/infrastructure/services/laravel_backend/backend_contract.dart';
import 'package:unifast_portal/infrastructure/services/laravel_backend/mock_backend.dart';

class Application extends ApplicationWebContract {

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
