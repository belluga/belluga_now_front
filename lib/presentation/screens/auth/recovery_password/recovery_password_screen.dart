import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/controllers/auth_login_controller_contract.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/common/widgets/button_loading.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/auth/recovery_password/controller/recovery_password_token_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_laravel_backend_boilerplate/application/router/app_router.gr.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'widgets/recovery_password_insert_email_widget.dart';
import 'widgets/recovery_password_token_widget.dart';



@RoutePage()
class RecoveryPasswordScreen extends StatefulWidget {
  const RecoveryPasswordScreen({super.key});

  @override
  State<RecoveryPasswordScreen> createState() => _RecoveryPasswordScreenState();
}

class _RecoveryPasswordScreenState extends State<RecoveryPasswordScreen> {
  final _controller = GetIt.I.registerSingleton<AuthRecoveryPasswordController>(AuthRecoveryPasswordController());

  bool mostrarCodigo = false;
  final List<TextEditingController> codigoControllers = List.generate(6, (_) => TextEditingController());

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
                          mostrarCodigo 
                            ? RecoveryPasswordTokenWidget(
                                controllers: codigoControllers,
                                onSubmit: _validarCodigo
                                ) 
                            : RecoveryPasswordInsertEmailWidget(controller: _controller),
                          const SizedBox(height: 240),
                          mostrarCodigo
                            ? const SizedBox()
                            : StreamValueBuilder<bool>(
                            streamValue: _controller.loading,
                            builder: (context, isLoading) {
                              return ButtonLoading(
                                onPressed: isLoading
                                ? null
                                : () {
                                    setState(() {
                                      mostrarCodigo = true;
                                    });
                                    _controller.submit();
                                  },
                            loadingStatusStreamValue: _controller.loading,
                            label: "Enviar Código",
                            );
                          }, 
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

  void _validarCodigo(String codigo) {
  if (codigo != '123456') {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Código inválido")),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Código válido!")),
    );
  }
}
  
  Future<void> navigateToAuthorizedPage() async =>
      await context.router.replace(const ProtectedRoute());

 // Future<void> tryLoginWithEmailPassword() async {
 //   await _controller.tryLoginWithEmailPassword();
 //   navigateToAuthorizedPage();
 // }

/*  SnackBar get _messageSnack {
    return SnackBar(
      backgroundColor: Theme.of(context).colorScheme.error,
      content: SizedBox(
        height: 160,
        child: Center(
          child: Text(_controller.generalErrorStreamValue.value ?? ""),
        ),
      ),
    );
  } */

  @override
  void dispose() {
    super.dispose();
    GetIt.I.unregister<AuthLoginControllerContract>();
  }
  
}