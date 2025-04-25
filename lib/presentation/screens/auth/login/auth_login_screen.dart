import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/controllers/auth_login_controller_contract.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/common/widgets/button_loading.dart';
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
      body: Stack(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,              
              children: [
                SizedBox(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Image.asset(
                    'assets/images/tela_login.jpeg',
                    fit: BoxFit.cover
                  ),
                ),
                const SizedBox(height: 35),
                const Text("Login"),
                const SingleChildScrollView(
                  child: AuthLoginnForm(),
                ),
                
                ButtonLoading(
                  onPressed: tryLoginWithEmailPassword,
                  loadingStatusStreamValue: _controller.buttonLoadingValue,
                  label: "Entrar",
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
          Positioned(
            child: const Text("Esqueci minha senha. Recuperar agora"),
          ),
          Positioned(          
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              width: double.infinity,
              height: 40,
              child: Image.asset(
                'assets/images/rodape.jpeg',
                fit: BoxFit.cover
              ),
            ),
          ),
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
