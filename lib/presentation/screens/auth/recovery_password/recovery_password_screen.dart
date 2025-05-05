import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/application/configurations/widget_keys.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/controllers/auth_login_controller_contract.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/common/widgets/button_loading.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/auth/login/controller/auth_login_controller.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/auth/widgets/auth_email_field.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_laravel_backend_boilerplate/application/router/app_router.gr.dart';
import 'package:stream_value/main.dart';


@RoutePage()
class RecoveryPasswordScreen extends StatefulWidget {
  const RecoveryPasswordScreen({super.key});

  @override
  State<RecoveryPasswordScreen> createState() => _RecoveryPasswordScreenState();
}

class _RecoveryPasswordScreenState extends State<RecoveryPasswordScreen> {
  final _controller = GetIt.I
      .registerSingleton<AuthLoginController>(AuthLoginController());

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
          Column(     
              children: [
                SizedBox(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.50,
                  child: Image.asset(
                    'assets/images/tela_login.jpeg',
                    fit: BoxFit.cover
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          const Text(
                            "Recuperar Senha",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold
                              ),
                            ),
                          const SizedBox(height: 20),
                          StreamValueBuilder<bool>(
                            streamValue: _controller.fieldEnabled,
                            builder: (context, fieldEnabled) {
                              return Form(
                                key: _controller.loginFormKey,
                                child: AuthEmailField(
                                  key: WidgetKeys.auth.loginEmailField,
                                  formFieldController: _controller.emailController,
                                  isEnabled: fieldEnabled,  
                                ),
                              );
                            },
                            ),
                          const SizedBox(height: 240),
                            ButtonLoading(
                            onPressed: tryLoginWithEmailPassword,
                            loadingStatusStreamValue: _controller.buttonLoadingValue,
                            label: "Enviar Código",
                            ), 
                          const SizedBox(height: 30), // Espaço pro rodapé
                        ],
                      )
                    ),
                  ),
                )
              ],
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
  
  Future<void> navigateToAuthorizedPage() async =>
      await context.router.replace(const ProtectedRoute());

  Future<void> tryLoginWithEmailPassword() async {
    await _controller.tryLoginWithEmailPassword();
    navigateToAuthorizedPage();
  }

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