import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/shared/auth/screens/auth_create_new_password_screen/widgets/create_new_password_widget.dart';
import 'package:belluga_now/presentation/tenant_public/auth/login/controllers/create_password_controller_contract.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class AuthCreateNewPasswordScreen extends StatefulWidget {
  const AuthCreateNewPasswordScreen({
    super.key,
  });

  @override
  State<AuthCreateNewPasswordScreen> createState() =>
      _AuthCreateNewPasswordScreenState();
}

class _AuthCreateNewPasswordScreenState
    extends State<AuthCreateNewPasswordScreen> {
  final CreatePasswordControllerContract _controller =
      GetIt.I.get<CreatePasswordControllerContract>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<String?>(
      streamValue: _controller.generalErrorStreamValue,
      builder: (context, error) {
        _handleGeneralError(error);
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
                      fit: BoxFit.cover,
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
                              'Criar Nova Senha',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            CreateNewPasswordWidget(controller: _controller),
                          ],
                        ),
                      ),
                    ),
                  ),
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
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleGeneralError(String? error) {
    if (error == null || error.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(_messageSnack);
      _controller.clearGeneralError();
    });
  }

  Future<void> navigateToDashboard() async =>
      context.router.replace(const TenantHomeRoute());

  SnackBar get _messageSnack {
    return SnackBar(
      backgroundColor: Theme.of(context).colorScheme.error,
      content: SizedBox(
        height: 160,
        child: Center(
          child: Text(_controller.generalErrorStreamValue.value ?? ''),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
