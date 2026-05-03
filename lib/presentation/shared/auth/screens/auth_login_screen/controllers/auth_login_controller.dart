import 'package:belluga_now/presentation/tenant_public/auth/login/controllers/auth_login_controller_contract.dart';

class AuthLoginController extends AuthLoginControllerContract {
  AuthLoginController({
    super.authRepository,
    super.initialEmail,
    super.initialPassword,
  });
}
