import 'package:flutter/material.dart';

class RecoveryPasswordTokenWidget extends StatelessWidget {
  final List<TextEditingController> controllers;
  final void Function(String token) onSubmit;

  const RecoveryPasswordTokenWidget({
    super.key,
    required this.controllers,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
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
            return Container(
              width: 40,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: controllers[index],
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
                    final token = controllers.map((c) => c.text).join();
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
