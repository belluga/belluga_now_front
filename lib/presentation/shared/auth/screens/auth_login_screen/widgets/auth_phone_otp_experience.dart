import 'dart:async';

import 'package:belluga_form_validation/belluga_form_validation.dart';
import 'package:belluga_now/application/configurations/widget_keys.dart';
import 'package:belluga_now/presentation/shared/auth/screens/auth_login_screen/widgets/auth_phone_otp_form.dart';
import 'package:belluga_now/presentation/shared/widgets/button_loading.dart';
import 'package:belluga_now/presentation/shared/widgets/main_logo.dart';
import 'package:belluga_now/presentation/tenant_public/auth/login/controllers/auth_login_controller_contract.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class AuthPhoneOtpExperience extends StatelessWidget {
  const AuthPhoneOtpExperience({
    super.key,
    required this.controller,
    required this.onBack,
  });

  final AuthLoginControllerContract controller;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<AuthPhoneOtpStep>(
      streamValue: controller.phoneOtpStepStreamValue,
      builder: (context, step) {
        return StreamValueBuilder<bool>(
          streamValue: controller.buttonLoadingValue,
          builder: (context, isLoading) {
            return StreamValueBuilder<bool>(
              streamValue: controller.fieldEnabled,
              builder: (context, enabled) {
                return StreamValueBuilder<String?>(
                  streamValue: controller.generalErrorStreamValue,
                  builder: (context, generalError) {
                    return Scaffold(
                      resizeToAvoidBottomInset: true,
                      body: SafeArea(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final horizontalPadding =
                                width > 520 ? (width - 430) / 2 : 24.0;

                            return SingleChildScrollView(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                12,
                                horizontalPadding,
                                24,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight - 36,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _AuthOtpTopBar(
                                      controller: controller,
                                      onBack: onBack,
                                    ),
                                    const SizedBox(height: 28),
                                    _AuthOtpStepHeader(step: step),
                                    const SizedBox(height: 24),
                                    _AuthOtpPanel(
                                      step: step,
                                      controller: controller,
                                      enabled: enabled,
                                      isLoading: isLoading,
                                      generalError: generalError,
                                    ),
                                    const SizedBox(height: 18),
                                    _AuthOtpTrustNote(step: step),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _AuthOtpTopBar extends StatelessWidget {
  const _AuthOtpTopBar({
    required this.controller,
    required this.onBack,
  });

  final AuthLoginControllerContract controller;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: MainLogo(
              appData: controller.appData,
              width: 112,
              height: 30,
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthOtpStepHeader extends StatelessWidget {
  const _AuthOtpStepHeader({
    required this.step,
  });

  final AuthPhoneOtpStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPhoneEntry = step == AuthPhoneOtpStep.phoneEntry;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AuthOtpStepIndicator(step: step),
        const SizedBox(height: 18),
        Text(
          isPhoneEntry ? 'Entrar com telefone' : 'Confirme o código',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isPhoneEntry
              ? 'Use seu número para entrar ou criar sua conta.'
              : 'Digite os 6 dígitos recebidos para continuar.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _AuthOtpStepIndicator extends StatelessWidget {
  const _AuthOtpStepIndicator({
    required this.step,
  });

  final AuthPhoneOtpStep step;

  @override
  Widget build(BuildContext context) {
    final currentIndex = step == AuthPhoneOtpStep.phoneEntry ? 1 : 2;

    return Row(
      children: [
        Expanded(
          child: _AuthOtpStepPill(
            number: '1',
            label: 'Telefone',
            selected: currentIndex == 1,
            completed: currentIndex > 1,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _AuthOtpStepPill(
            number: '2',
            label: 'Código',
            selected: currentIndex == 2,
            completed: false,
          ),
        ),
      ],
    );
  }
}

class _AuthOtpStepPill extends StatelessWidget {
  const _AuthOtpStepPill({
    required this.number,
    required this.label,
    required this.selected,
    required this.completed,
  });

  final String number;
  final String label;
  final bool selected;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final active = selected || completed;
    final backgroundColor = active
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final borderColor =
        active ? colorScheme.primary : colorScheme.outlineVariant;
    final labelColor =
        active ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: completed
                  ? Icon(
                      Icons.check,
                      size: 16,
                      color: colorScheme.onPrimary,
                    )
                  : Text(
                      number,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: active
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: labelColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthOtpPanel extends StatelessWidget {
  const _AuthOtpPanel({
    required this.step,
    required this.controller,
    required this.enabled,
    required this.isLoading,
    required this.generalError,
  });

  final AuthPhoneOtpStep step;
  final AuthLoginControllerContract controller;
  final bool enabled;
  final bool isLoading;
  final String? generalError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthPhoneOtpForm(
              controller: controller,
              showOtpDestinationHeader:
                  step == AuthPhoneOtpStep.otpVerification,
              showOtpSecondaryActions: false,
            ),
            FormValidationGlobalErrorsBuilder(
              validationStreamValue: controller.phoneOtpValidationStreamValue,
              targetId:
                  AuthLoginControllerContract.phoneOtpValidationTargetGlobal,
              builder: (context, messages) {
                final message =
                    messages.isNotEmpty ? messages.first : generalError?.trim();
                if (message == null || message.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: _AuthOtpErrorMessage(message: message),
                );
              },
            ),
            const SizedBox(height: 18),
            Semantics(
              identifier: 'auth_login_submit_button',
              button: true,
              onTap: enabled ? _submitCurrentStep : null,
              child: ButtonLoading(
                key: WidgetKeys.auth.loginButton,
                onPressed: enabled ? _submitCurrentStep : null,
                isLoading: isLoading,
                label: _primaryButtonLabel(),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            if (step == AuthPhoneOtpStep.otpVerification) ...[
              const SizedBox(height: 10),
              _OtpSecondaryActions(
                controller: controller,
                enabled: enabled,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _primaryButtonLabel() {
    return switch (step) {
      AuthPhoneOtpStep.phoneEntry => 'Continuar via WhatsApp',
      AuthPhoneOtpStep.otpVerification => 'Confirmar código',
    };
  }

  void _submitCurrentStep() {
    if (step == AuthPhoneOtpStep.phoneEntry) {
      unawaited(controller.requestPhoneOtpChallenge());
      return;
    }
    unawaited(controller.verifyPhoneOtpChallenge());
  }
}

class _AuthOtpErrorMessage extends StatelessWidget {
  const _AuthOtpErrorMessage({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              color: colorScheme.onErrorContainer,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onErrorContainer,
                      height: 1.3,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpSecondaryActions extends StatelessWidget {
  const _OtpSecondaryActions({
    required this.controller,
    required this.enabled,
  });

  final AuthLoginControllerContract controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final challenge = controller.currentPhoneOtpChallengeStreamValue.value;
    final isSms = challenge?.deliveryChannel ==
        AuthLoginControllerContract.phoneOtpDeliveryChannelSms;
    final showSmsFallback = controller.isPhoneOtpSmsFallbackAvailable && !isSms;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        TextButton.icon(
          onPressed: enabled ? controller.editPhoneNumber : null,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Editar telefone'),
        ),
        TextButton.icon(
          onPressed: enabled ? _requestNewCode : null,
          icon: const Icon(Icons.refresh_outlined),
          label: const Text('Reenviar código'),
        ),
        if (showSmsFallback)
          PopupMenuButton<String>(
            enabled: enabled,
            tooltip: 'Outras formas',
            onSelected: (_) => _requestSmsCode(),
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: AuthLoginControllerContract.phoneOtpDeliveryChannelSms,
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.sms_outlined),
                  title: Text('Receber por SMS'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.more_horiz_outlined),
                  const SizedBox(width: 8),
                  Text(
                    'Outras formas',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _requestNewCode() {
    unawaited(controller.resendPhoneOtpChallenge());
  }

  void _requestSmsCode() {
    unawaited(controller.requestPhoneOtpSmsChallenge());
  }
}

class _AuthOtpTrustNote extends StatelessWidget {
  const _AuthOtpTrustNote({
    required this.step,
  });

  final AuthPhoneOtpStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Text(
      step == AuthPhoneOtpStep.phoneEntry
          ? 'Enviaremos o código para seu número WhatsApp.'
          : 'O código expira em alguns minutos. Solicite outro se necessário.',
      textAlign: TextAlign.center,
      style: theme.textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
        height: 1.3,
      ),
    );
  }
}
