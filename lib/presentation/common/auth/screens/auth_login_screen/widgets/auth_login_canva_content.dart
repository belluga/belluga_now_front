import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/common/auth/screens/auth_login_screen/widgets/auth_login_form.dart';
import 'package:belluga_now/presentation/common/widgets/button_loading.dart';
import 'package:belluga_now/presentation/landlord/auth/controllers/landlord_login_controller.dart';
import 'package:belluga_now/presentation/landlord/auth/widgets/landlord_login_sheet.dart';
import 'package:belluga_now/presentation/tenant/auth/login/controllers/auth_login_controller_contract.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class AuthLoginCanvaContent extends StatefulWidget {
  const AuthLoginCanvaContent({
    super.key,
    required this.navigateToPasswordRecover,
    required this.controller,
    required this.landlordLoginController,
  });

  final Future<void> Function() navigateToPasswordRecover;
  final AuthLoginControllerContract controller;
  final LandlordLoginController landlordLoginController;

  @override
  State<AuthLoginCanvaContent> createState() => _AuthLoginCanvaContentState();
}

class _AuthLoginCanvaContentState extends State<AuthLoginCanvaContent>
    with WidgetsBindingObserver {
  AuthLoginControllerContract get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<bool?>(
      streamValue: _controller.loginResultStreamValue,
      builder: (context, loginResult) {
        _handleLoginResult(loginResult);
        return StreamValueBuilder<bool?>(
          streamValue: _controller.signUpResultStreamValue,
          builder: (context, signUpResult) {
            _handleSignUpResult(signUpResult);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreamValueBuilder(
                  streamValue:
                      _controller.sliverAppBarController.keyboardIsOpened,
                  builder: (context, isOpened) {
                    if (isOpened) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Entrar',
                          style: TextTheme.of(context).titleLarge,
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),
                AuthLoginForm(controller: _controller),
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
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                StreamValueBuilder<bool>(
                  streamValue: _controller.buttonLoadingValue,
                  builder: (context, isLoading) {
                    return ButtonLoading(
                      onPressed: tryLoginWithEmailPassword,
                      isLoading: isLoading,
                      label: 'Entrar',
                    );
                  },
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
          },
        );
      },
    );
  }

  void tryLoginWithEmailPassword() {
    unawaited(_controller.tryLoginWithEmailPassword());
  }

  void _navigateToAuthorizedPage() =>
      context.router.replace(const TenantHomeRoute());

  Future<void> _openSignupSheet() async {
    _controller.resetSignupControllers();
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
                  controller: _controller.signupNameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller.signupEmailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller.signupPasswordController,
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
                      _controller.signupNameController.text,
                      _controller.signupEmailController.text,
                      _controller.signupPasswordController.text,
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
    final router = context.router;
    final didLogin = await showLandlordLoginSheet(
      context,
      controller: widget.landlordLoginController,
    );
    if (!didLogin) {
      return;
    }
    router.replaceAll([const TenantAdminShellRoute()]);
  }

  void _submitSignup(
    BuildContext ctx,
    String name,
    String email,
    String password,
  ) {
    final messenger = ScaffoldMessenger.of(ctx);
    final normalizedName = name.trim();
    final normalizedEmail = email.trim();
    if (normalizedName.isEmpty ||
        normalizedEmail.isEmpty ||
        password.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos.')),
      );
      return;
    }
    unawaited(
      _controller.signUpWithEmailPassword(
        normalizedName,
        normalizedEmail,
        password,
      ),
    );
  }

  void _handleLoginResult(bool? authorized) {
    if (authorized == null) return;
    if (authorized) {
      _navigateToAuthorizedPage();
    }
    _controller.clearLoginResult();
  }

  void _handleSignUpResult(bool? authorized) {
    if (authorized == null) return;
    if (authorized) {
      Navigator.of(context).maybePop();
      _navigateToAuthorizedPage();
    }
    _controller.clearSignUpResult();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
