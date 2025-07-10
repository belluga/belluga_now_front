import 'package:unifast_portal/application/application_mobile_contract.dart';
import 'package:unifast_portal/domain/repositories/auth_repository_contract.dart';
import 'package:unifast_portal/domain/user/user_belluga.dart';
import 'package:unifast_portal/infrastructure/repositories/auth_repository.dart';
import 'package:unifast_portal/infrastructure/services/laravel_backend/backend_contract.dart';
import 'package:unifast_portal/infrastructure/services/laravel_backend/mock_backend.dart';

class Application extends ApplicationMobileContract {

  Application({super.key});

  @override
  AuthRepositoryContract<UserBelluga> initAuthRepository() => AuthRepository();

  @override
  BackendContract initBackendRepository() => MockBackend();
  
}
