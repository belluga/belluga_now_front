import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/common/auth/screens/auth_create_new_password_screen/widgets/create_new_password_widget.dart';
import 'package:belluga_now/presentation/tenant/auth/login/controllers/create_password_controller_contract.dart';
import 'package:flutter/material.dart';

class AuthCreateNewPasswordScreen extends StatefulWidget {
  const AuthCreateNewPasswordScreen({
    super.key,
    required this.controller,
  });

  final CreatePasswordControllerContract controller;

  @override
  State<AuthCreateNewPasswordScreen> createState() =>
      _AuthCreateNewPasswordScreenState();
}

class _AuthCreateNewPasswordScreenState
    extends State<AuthCreateNewPasswordScreen> {
  CreatePasswordControllerContract get _controller => widget.controller;
  StreamSubscription<String?>? _generalErrorSubscription;

  @override
  void initState() {
    super.initState();
    _generalErrorSubscription =
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
  }

  void _onGeneralError(String? error) {
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(_messageSnack);
    }
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
    _generalErrorSubscription?.cancel();
    super.dispose();
  }
}
