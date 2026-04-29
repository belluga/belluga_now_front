import 'dart:async';

import 'package:belluga_now/application/configurations/widget_keys.dart';
import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/shared/auth/screens/auth_login_screen/widgets/auth_login_form.dart';
import 'package:belluga_now/presentation/shared/auth/screens/auth_login_screen/widgets/auth_phone_otp_form.dart';
import 'package:belluga_now/presentation/shared/widgets/button_loading.dart';
import 'package:belluga_now/presentation/landlord_area/auth/controllers/auth_login_landlord_controller.dart';
import 'package:belluga_now/presentation/landlord_area/auth/widgets/landlord_login_sheet.dart';
import 'package:belluga_now/presentation/tenant_public/auth/login/controllers/auth_login_controller_contract.dart';
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
  final AuthLoginLandlordController? landlordLoginController;

  AuthLoginControllerContract get _controller =>
      controller ?? GetIt.I.get<AuthLoginControllerContract>();
  AuthLoginLandlordController get _landlordController =>
      landlordLoginController ?? GetIt.I.get<AuthLoginLandlordController>();

  @override
  Widget build(BuildContext context) {
    final usesPhoneOtp = !_controller.isLandlordContext;

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
                  usesPhoneOtp ? 'Entrar com telefone' : 'Entrar',
                  style: TextTheme.of(context).titleLarge,
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
        if (usesPhoneOtp)
          AuthPhoneOtpForm(controller: _controller)
        else
          AuthLoginForm(controller: _controller),
        if (!usesPhoneOtp)
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
        StreamValueBuilder<AuthPhoneOtpStep>(
          streamValue: _controller.phoneOtpStepStreamValue,
          builder: (context, step) {
            return StreamValueBuilder<bool>(
              streamValue: _controller.buttonLoadingValue,
              builder: (context, isLoading) {
                final label =
                    usesPhoneOtp ? _phoneOtpButtonLabel(step) : 'Entrar';
                return Semantics(
                  identifier: 'auth_login_submit_button',
                  button: true,
                  onTap: usesPhoneOtp
                      ? _submitPhoneOtpStep
                      : _tryLoginWithEmailPassword,
                  child: ButtonLoading(
                    key: WidgetKeys.auth.loginButton,
                    onPressed: usesPhoneOtp
                        ? _submitPhoneOtpStep
                        : _tryLoginWithEmailPassword,
                    isLoading: isLoading,
                    label: label,
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 16),
        if (_controller.isLandlordContext)
          Semantics(
            identifier: 'auth_login_enter_as_admin_button',
            button: true,
            onTap: () => _openLandlordLogin(context),
            child: TextButton(
              onPressed: () => _openLandlordLogin(context),
              child: const Text('Entrar como Admin'),
            ),
          ),
      ],
    );
  }

  void _tryLoginWithEmailPassword() {
    unawaited(_controller.tryLoginWithEmailPassword());
  }

  void _submitPhoneOtpStep() {
    final step = _controller.phoneOtpStepStreamValue.value;
    if (step == AuthPhoneOtpStep.phoneEntry) {
      unawaited(_controller.requestPhoneOtpChallenge());
      return;
    }

    unawaited(_controller.verifyPhoneOtpChallenge());
  }

  String _phoneOtpButtonLabel(AuthPhoneOtpStep step) {
    return switch (step) {
      AuthPhoneOtpStep.phoneEntry => 'Receber codigo',
      AuthPhoneOtpStep.otpVerification => 'Confirmar codigo',
    };
  }

  Future<void> _openLandlordLogin(BuildContext context) async {
    final router = context.router;
    final shouldOpenAdmin = await _controller.requestLandlordAdminLogin(
      performLogin: () => showLandlordLoginSheet(
        context,
        controller: _landlordController,
      ),
    );
    _navigateToLandlordAdminIfNeeded(router, shouldOpenAdmin);
  }

  void _navigateToLandlordAdminIfNeeded(
      StackRouter router, bool shouldOpenAdmin) {
    if (!shouldOpenAdmin) {
      return;
    }
    router.replaceAll([const TenantAdminShellRoute()]);
  }
}
