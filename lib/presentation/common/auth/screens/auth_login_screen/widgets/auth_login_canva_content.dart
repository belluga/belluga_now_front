import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/common/auth/screens/auth_login_screen/widgets/auth_login_form.dart';
import 'package:belluga_now/presentation/common/widgets/button_loading.dart';
import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/presentation/landlord/auth/widgets/landlord_login_sheet.dart';
import 'package:belluga_now/presentation/tenant/auth/login/controllers/auth_login_controller_contract.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class AuthLoginCanvaContent extends StatefulWidget {
  const AuthLoginCanvaContent({
    super.key,
    required this.navigateToPasswordRecover,
  }) : controller = null;

  @visibleForTesting
  const AuthLoginCanvaContent.withController(
    this.controller, {
    super.key,
    required this.navigateToPasswordRecover,
  });

  final Future<void> Function() navigateToPasswordRecover;
  final AuthLoginControllerContract? controller;

  @override
  State<AuthLoginCanvaContent> createState() => _AuthLoginCanvaContentState();
}

class _AuthLoginCanvaContentState extends State<AuthLoginCanvaContent>
    with WidgetsBindingObserver {
  AuthLoginControllerContract get _controller =>
      widget.controller ?? GetIt.I.get<AuthLoginControllerContract>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StreamValueBuilder(
          streamValue: _controller.sliverAppBarController.keyboardIsOpened,
          builder: (context, isOpened) {
            if (isOpened) {
              return const SizedBox.shrink();
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Entrar', style: TextTheme.of(context).titleLarge),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
        AuthLoginForm(),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Esqueci minha senha.',
                  style: TextStyle(fontSize: 12),
                ),
                TextButton(
                  onPressed: widget.navigateToPasswordRecover,
                  child: const Text(
                    'Recuperar agora',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        ButtonLoading(
          onPressed: tryLoginWithEmailPassword,
          loadingStatusStreamValue: _controller.buttonLoadingValue,
          label: 'Entrar',
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _openSignupSheet,
          child: const Text('Criar conta'),
        ),
        TextButton(
          onPressed: _openLandlordLogin,
          child: const Text('Entrar como Admin'),
        ),
      ],
    );
  }

  Future<void> tryLoginWithEmailPassword() async {
    await _controller.tryLoginWithEmailPassword();
    if (_controller.isAuthorized) {
      _navigateToAuthorizedPage();
    }
  }

  Future<void> _navigateToAuthorizedPage() async =>
      context.router.replace(const TenantHomeRoute());

  Future<void> _openSignupSheet() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
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
                  'Criar conta',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    border: OutlineInputBorder(),
                  ),
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
                    onPressed: () => _submitSignup(
                      ctx,
                      nameController.text,
                      emailController.text,
                      passwordController.text,
                    ),
                    child: const Text('Criar conta'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openLandlordLogin() async {
    final didLogin = await showLandlordLoginSheet(context);
    if (didLogin && context.mounted) {
      final adminMode = GetIt.I.get<AdminModeRepositoryContract>();
      await adminMode.setLandlordMode();
      context.router.replaceAll([const TenantAdminShellRoute()]);
    }
  }

  Future<void> _submitSignup(
    BuildContext ctx,
    String name,
    String email,
    String password,
  ) async {
    final normalizedName = name.trim();
    final normalizedEmail = email.trim();
    if (normalizedName.isEmpty ||
        normalizedEmail.isEmpty ||
        password.trim().isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos.')),
      );
      return;
    }

    final authRepository = GetIt.I.get<AuthRepositoryContract>();
    try {
      await authRepository.signUpWithEmailPassword(
        normalizedName,
        normalizedEmail,
        password,
      );
      if (ctx.mounted) {
        Navigator.of(ctx).pop();
      }
      if (context.mounted) {
        if (authRepository.isAuthorized) {
          context.router.replace(const TenantHomeRoute());
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Falha ao autenticar apÃ³s o cadastro.'),
            ),
          );
        }
      }
    } catch (e) {
      if (!ctx.mounted) {
        return;
      }
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('Falha ao criar conta: $e')),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
