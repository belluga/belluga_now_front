import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

Future<bool> showLandlordLoginSheet(BuildContext context) async {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  var didLogin = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Entrar como Admin',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final email = emailController.text.trim();
                    final password = passwordController.text.trim();
                    if (email.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Informe e-mail e senha.')),
                      );
                      return;
                    }
                    final landlordAuth =
                        GetIt.I.get<LandlordAuthRepositoryContract>();
                    try {
                      await landlordAuth.loginWithEmailPassword(
                        email,
                        password,
                      );
                      didLogin = true;
                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                      }
                    } catch (e) {
                      if (!ctx.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Falha ao entrar: $e')),
                      );
                    }
                  },
                  child: const Text('Entrar'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  emailController.dispose();
  passwordController.dispose();
  return didLogin;
}
