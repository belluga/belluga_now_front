import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/controllers/auth_login_controller_contract.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/repositories/auth_repository_contract.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/common/widgets/button_loading.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/auth/create_new_password/auth_create_new_password.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/auth/recovery_password/controller/recovery_password_token_controller.dart';
import 'package:get_it/get_it.dart';
import 'dart:math';
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

  final _authRepository = GetIt.I<AuthRepositoryContract>();

  bool mostrarCodigo = false;
  String errorMessage = "";
  String? codigoEnviado;
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
                          const SizedBox(height: 5),
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
                                    _enviarCodigoParaEmail();
                                  },
                            loadingStatusStreamValue: _controller.loading,
                            label: "Enviar Código",
                            );
                          }, 
                          ),
                          if (errorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              errorMessage,
                              style: TextStyle(color: Colors.red, fontSize: 14),
                            ),
                          ), // Espaço pro rodapé
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

  void _enviarCodigoParaEmail() {
    final email = _controller.emailController.value;
    // Simula o envio do código para o email
    setState(() {
      codigoEnviado = _gerarCodigoAleatorio();
      print("Código enviado para o email: $codigoEnviado");
      
      _authRepository.sendTokenRecoveryPassword(email, codigoEnviado!); // Atualiza a mensagem de sucesso
    });
  }

  String _gerarCodigoAleatorio() {
    Random random = Random();
    int codigo = 100000 + random.nextInt(900000); // Gera um código aleatório de 6 dígitos
    return codigo.toString();
  }

  void _validarCodigo(String codigo) {
    if (codigo != codigoEnviado) {
      setState(() {
        errorMessage = "Código inválido"; // Atualiza a mensagem de erro
      });
    } else {
      setState(() {
        errorMessage = "Código válido!"; // Atualiza a mensagem de sucesso
      });
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AuthCreateNewPasswordScreen()),
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