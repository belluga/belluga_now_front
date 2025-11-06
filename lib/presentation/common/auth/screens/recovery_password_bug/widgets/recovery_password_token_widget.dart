import 'package:belluga_now/presentation/tenant/auth/login/controllers/recovery_password_token_controller_contract.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class RecoveryPasswordTokenWidget extends StatelessWidget {
  const RecoveryPasswordTokenWidget({
    super.key,
    required this.onSubmit,
  });

  final void Function(String token) onSubmit;

  @override
  Widget build(BuildContext context) {
    final controller =
        GetIt.I.get<AuthRecoveryPasswordControllerContract>();
    final tokenControllers = controller.tokenControllers;

    return Column(
      children: [
        const Text(
          "Insira o código que foi enviado no seu email",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            final textController = tokenControllers[index];
            return Container(
              width: 40,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: textController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                onChanged: (value) {
                  if (value.isNotEmpty && index < 5) {
                    FocusScope.of(context).nextFocus();
                  }

                  if (value.isEmpty && index > 0) {
                    FocusScope.of(context).previousFocus();
                  }

                  if (index == 5 && value.isNotEmpty) {
                    final token =
                        tokenControllers.map((c) => c.text).join();
                    onSubmit(token);
                  }
                },
                decoration: const InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
