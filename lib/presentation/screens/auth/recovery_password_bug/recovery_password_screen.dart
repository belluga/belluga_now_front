import 'package:flutter/material.dart';
import 'package:belluga_now/domain/controllers/recovery_password_token_controller_contract.dart';
import 'package:get_it/get_it.dart';

class RecoveryPasswordScreen extends StatefulWidget {
  final String? initialEmmail;

  const RecoveryPasswordScreen({super.key, this.initialEmmail});

  @override
  State<RecoveryPasswordScreen> createState() => _RecoveryPasswordScreenState();
}

class _RecoveryPasswordScreenState extends State<RecoveryPasswordScreen> {
  late AuthRecoveryPasswordControllerContract _controller;

  @override
  void initState() {
    super.initState();
    _controller = GetIt.I.get<AuthRecoveryPasswordControllerContract>(
      param1: widget.initialEmmail,
    );
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
                          "Recuperar Senha",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
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

  @override
  void dispose() {
    super.dispose();
    _controller.onDispose();
  }
}
