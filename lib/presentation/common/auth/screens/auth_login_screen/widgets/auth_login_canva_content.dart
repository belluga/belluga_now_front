import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/common/auth/screens/auth_login_screen/widgets/auth_login_form.dart';
import 'package:belluga_now/presentation/common/auth/screens/auth_login_screen/widgets/auth_signup_sheet.dart';
import 'package:belluga_now/presentation/common/widgets/button_loading.dart';
import 'package:belluga_now/presentation/landlord/auth/controllers/landlord_login_controller.dart';
import 'package:belluga_now/presentation/landlord/auth/widgets/landlord_login_sheet.dart';
import 'package:belluga_now/presentation/tenant/auth/login/controllers/auth_login_controller_contract.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class AuthLoginCanvaContent extends StatelessWidget {
  const AuthLoginCanvaContent({
    super.key,
    required this.navigateToPasswordRecover,
    this.controller,
    this.landlordLoginController,
  });

  final Future<void> Function() navigateToPasswordRecover;
  final AuthLoginControllerContract? controller;
  final LandlordLoginController? landlordLoginController;

  AuthLoginControllerContract get _controller =>
      controller ?? GetIt.I.get<AuthLoginControllerContract>();
  LandlordLoginController get _landlordController =>
      landlordLoginController ?? GetIt.I.get<LandlordLoginController>();

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
                  onPressed: navigateToPasswordRecover,
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
              onPressed: _tryLoginWithEmailPassword,
              isLoading: isLoading,
              label: 'Entrar',
            );
          },
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => _openSignupSheet(context),
          child: const Text('Criar conta'),
        ),
        TextButton(
          onPressed: () => _openLandlordLogin(context),
          child: const Text('Entrar como Admin'),
        ),
      ],
    );
  }

  void _tryLoginWithEmailPassword() {
    unawaited(_controller.tryLoginWithEmailPassword());
  }

  Future<void> _openSignupSheet(BuildContext context) async {
    _controller.resetSignupControllers();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AuthSignupSheet(controller: _controller),
    );
  }

  Future<void> _openLandlordLogin(BuildContext context) async {
    final router = context.router;
    final didLogin = await showLandlordLoginSheet(
      context,
      controller: _landlordController,
    );
    if (!didLogin) {
      return;
    }
    router.replaceAll([const TenantAdminShellRoute()]);
  }
}
