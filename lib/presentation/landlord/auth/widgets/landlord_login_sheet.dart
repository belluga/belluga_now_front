import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/landlord/auth/controllers/landlord_login_controller.dart';
import 'package:flutter/material.dart';

Future<bool> showLandlordLoginSheet(
  BuildContext context, {
  required LandlordLoginController controller,
}) async {
  controller.resetForm();
  return _showLandlordLoginSheet(
    context,
    emailController: controller.emailController,
    passwordController: controller.passwordController,
    onSubmit: (email, password) async {
      await controller.enterAdminModeWithCredentials(email, password);
      return true;
    },
  );
}

Future<bool> showLandlordCredentialsSheet(
  BuildContext context, {
  required TextEditingController emailController,
  required TextEditingController passwordController,
  required Future<bool> Function(String email, String password) onSubmit,
}) {
  emailController.clear();
  passwordController.clear();
  return _showLandlordLoginSheet(
    context,
    emailController: emailController,
    passwordController: passwordController,
    onSubmit: onSubmit,
  );
}

Future<bool> _showLandlordLoginSheet(
  BuildContext context, {
  required TextEditingController emailController,
  required TextEditingController passwordController,
  required Future<bool> Function(String email, String password) onSubmit,
}) async {
  var didLogin = false;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: SingleChildScrollView(
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
              Semantics(
                identifier: 'landlord_login_sheet_email_field',
                textField: true,
                child: TextField(
                  key: const ValueKey('landlord_login_sheet_email_field'),
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                identifier: 'landlord_login_sheet_password_field',
                textField: true,
                child: TextField(
                  key: const ValueKey('landlord_login_sheet_password_field'),
                  controller: passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                identifier: 'landlord_login_sheet_submit_button',
                button: true,
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const ValueKey('landlord_login_sheet_submit_button'),
                    onPressed: () async {
                      final email = emailController.text.trim();
                      final password = passwordController.text.trim();
                      final messenger = ScaffoldMessenger.of(ctx);
                      final router = ctx.router;
                      if (email.isEmpty || password.isEmpty) {
                        messenger.showSnackBar(
                          const SnackBar(
                              content: Text('Informe e-mail e senha.')),
                        );
                        return;
                      }
                      try {
                        didLogin = await onSubmit(email, password);
                        router.pop();
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Falha ao entrar: $e')),
                        );
                      }
                    },
                    child: const Text('Entrar'),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  return didLogin;
}
