import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/application/router/app_router.gr.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/controllers/create_password_controller_contract.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/auth/create_new_password/controller/create_password_controller.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/auth/create_new_password/widgets/create_new_password_widget.dart';
import 'package:get_it/get_it.dart';

@RoutePage()
class AuthCreateNewPasswordScreen extends StatefulWidget {
  const AuthCreateNewPasswordScreen({super.key});

  @override
  State<AuthCreateNewPasswordScreen> createState() => _AuthCreateNewPasswordScreenState();
}

class _AuthCreateNewPasswordScreenState extends State<AuthCreateNewPasswordScreen> {
  final _controller = GetIt.I.registerSingleton<CreatePasswordControllerContract>(CreatePasswordController());

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
                            "Criar Nova Senha",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold
                              ),
                            ),
                          const CreateNewPasswordWidget()  // Espaço pro rodapé
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
    GetIt.I.unregister<AuthCreateNewPasswordScreen>();
  }

}
