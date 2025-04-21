import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/application/configurations/widget_keys.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/controllers/auth_login_controller_contract.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/auth/login/controller/auth_login_controller.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/auth/login/widgets/auth_login_form.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_laravel_backend_boilerplate/application/router/app_router.gr.dart';

@RoutePage()
class AuthLoginScreen extends StatefulWidget {
  const AuthLoginScreen({super.key});

  @override
  State<AuthLoginScreen> createState() => _AuthLoginScreenState();
}

class _AuthLoginScreenState extends State<AuthLoginScreen> {
  final _controller = GetIt.I
      .registerSingleton<AuthLoginControllerContract>(AuthLoginController());

  @override
  void initState() {
    super.initState();
    _controller.generalErrorStreamValue.stream.listen(_onGeneralError);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Entre em sua conta"),
                const SingleChildScrollView(
                  child: AuthLoginnForm(),
                ),
                ElevatedButton(
                  key: WidgetKeys.auth.loginButton,
                  onPressed: tryLoginWithEmailPassword,
                  child: const Text("Entrar"),
                ),
                // Row(
                //   children: [
                //     TextButton(
                //       key: WidgetKeys.auth.navigateToRecoverButton,
                //       onPressed: navigateToPasswordRecover,
                //       child: const Text("Esqueceu sua senha?"),
                //     ),
                //     TextButton(
                //       key: WidgetKeys.auth.navigateToSignupButton,
                //       onPressed: navigateToRegister,
                //       child: const Text("Não tem uma conta? Registre-se"),
                //     ),
                //   ],
                // )
              ],
            ),
          ),
          const Text("I agree with the Terms & Conditions"),
        ],
      ),
    );
  }

  void _onGeneralError(String? error) {
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(_messageSnack);
    }
  }

  Future<void> tryLoginWithEmailPassword() async {
    await _controller.tryLoginWithEmailPassword();
    navigateToAuthorizedPage();
  }

  // Future<void> navigateToPasswordRecover() async {
  //   await context.router.push(
  //     AuthPasswordRecoverRoute(
  //       initialEmail: _controller.emailController.text,
  //     ),
  //   );
  // }

  // Future<void> navigateToRegister() async {
  //   await context.router.push(AuthRegisterRoute(
  //     initialEmail: _controller.emailController.text,
  //   ));
  // }

  Future<void> navigateToAuthorizedPage() async =>
      await context.router.replace(const ProtectedRoute());

  SnackBar get _messageSnack {
    return SnackBar(
      backgroundColor: Theme.of(context).colorScheme.error,
      content: SizedBox(
        height: 160,
        child: Center(
          child: Text(_controller.generalErrorStreamValue.value ?? ""),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    GetIt.I.unregister<AuthLoginControllerContract>();
  }
}
