import 'package:flutter/material.dart';
import 'package:unifast_portal/domain/controllers/remember_password_contract.dart';
import 'package:get_it/get_it.dart';

class RememberPassword extends StatelessWidget {
  final RememberPasswordContract controller =
      GetIt.I<RememberPasswordContract>();

  RememberPassword({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: controller.stream,
      initialData: controller.value,
      builder: (context, snapshot) {
        final rememberPassword = snapshot.data ?? false;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Lembrar senha",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Switch(value: rememberPassword, onChanged: controller.set),
          ],
        );
      },
    );
  }
}
