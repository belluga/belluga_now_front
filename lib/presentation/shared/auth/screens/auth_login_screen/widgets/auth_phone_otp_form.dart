import 'dart:async';

import 'package:belluga_now/application/configurations/widget_keys.dart';
import 'package:belluga_now/presentation/tenant_public/auth/login/controllers/auth_login_controller_contract.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:pinput/pinput.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class AuthPhoneOtpForm extends StatelessWidget {
  const AuthPhoneOtpForm({
    super.key,
    required this.controller,
    this.showOtpDestinationHeader = true,
    this.showOtpSecondaryActions = true,
  });

  final AuthLoginControllerContract controller;
  final bool showOtpDestinationHeader;
  final bool showOtpSecondaryActions;

  AuthLoginControllerContract get _controller => controller;

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<AuthPhoneOtpStep>(
      streamValue: _controller.phoneOtpStepStreamValue,
      builder: (context, step) {
        return StreamValueBuilder<bool>(
          streamValue: _controller.fieldEnabled,
          builder: (context, enabled) {
            return switch (step) {
              AuthPhoneOtpStep.phoneEntry => _PhoneEntryForm(
                  controller: _controller,
                  enabled: enabled,
                ),
              AuthPhoneOtpStep.otpVerification => _OtpVerificationForm(
                  controller: _controller,
                  enabled: enabled,
                  showDestinationHeader: showOtpDestinationHeader,
                  showSecondaryActions: showOtpSecondaryActions,
                ),
            };
          },
        );
      },
    );
  }
}

class _PhoneEntryForm extends StatelessWidget {
  const _PhoneEntryForm({
    required this.controller,
    required this.enabled,
  });

  final AuthLoginControllerContract controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Form(
      key: controller.phoneOtpFormKey,
      child: PhoneFormField(
        key: WidgetKeys.auth.loginPhoneField,
        controller: controller.phoneNumberController,
        focusNode: controller.phoneFocusNode,
        enabled: enabled,
        shouldLimitLengthByCountry: true,
        countrySelectorNavigator:
            const CountrySelectorNavigator.modalBottomSheet(),
        isCountrySelectionEnabled: true,
        autofillHints: const [AutofillHints.telephoneNumber],
        textInputAction: TextInputAction.done,
        validator: controller.validatePhoneNumberValue,
        onChanged: controller.updatePhoneOtpInput,
        onSubmitted: (_) {
          if (enabled) {
            unawaited(controller.requestPhoneOtpChallenge());
          }
        },
        decoration: InputDecoration(
          labelText: 'Telefone',
          hintText: '(27) 99999-0000',
          helperText: 'Enviaremos um codigo pelo WhatsApp.',
          prefixIcon: const Icon(Icons.phone_outlined),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colorScheme.error, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colorScheme.error, width: 1.5),
          ),
          fillColor: colorScheme.surfaceContainerHighest,
          filled: true,
          helperMaxLines: 2,
        ),
      ),
    );
  }
}

class _OtpVerificationForm extends StatelessWidget {
  const _OtpVerificationForm({
    required this.controller,
    required this.enabled,
    required this.showDestinationHeader,
    required this.showSecondaryActions,
  });

  final AuthLoginControllerContract controller;
  final bool enabled;
  final bool showDestinationHeader;
  final bool showSecondaryActions;

  @override
  Widget build(BuildContext context) {
    final challenge = controller.currentPhoneOtpChallengeStreamValue.value;
    final phone = challenge?.phone ?? controller.phoneController.text.trim();
    final deliveryChannel = challenge?.deliveryChannel ??
        AuthLoginControllerContract.phoneOtpDeliveryChannelWhatsapp;
    final isSms = deliveryChannel ==
        AuthLoginControllerContract.phoneOtpDeliveryChannelSms;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Form(
      key: controller.otpCodeFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showDestinationHeader) ...[
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      isSms ? Icons.sms_outlined : Icons.chat_outlined,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Codigo enviado por '
                            '${_deliveryChannelLabel(deliveryChannel)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            phone,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          _buildOtpInput(theme, colorScheme),
          if (showSecondaryActions) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: enabled ? controller.editPhoneNumber : null,
                  child: const Text('Editar telefone'),
                ),
                TextButton(
                  onPressed: enabled ? _requestNewCode : null,
                  child: const Text('Reenviar codigo'),
                ),
                if (controller.isPhoneOtpSmsFallbackAvailable && !isSms)
                  TextButton.icon(
                    onPressed: enabled ? _requestSmsCode : null,
                    icon: const Icon(Icons.sms_outlined),
                    label: const Text('Receber por SMS'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _requestNewCode() {
    unawaited(controller.resendPhoneOtpChallenge());
  }

  void _requestSmsCode() {
    unawaited(controller.requestPhoneOtpSmsChallenge());
  }

  Widget _buildOtpInput(ThemeData theme, ColorScheme colorScheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final pinWidth = ((availableWidth - 40) / 6).clamp(36.0, 44.0);
        final basePinTheme = PinTheme(
          width: pinWidth,
          height: 52,
          textStyle: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
        );

        return Pinput(
          key: WidgetKeys.auth.loginOtpCodeField,
          length: 6,
          controller: controller.otpCodeController,
          focusNode: controller.otpCodeFocusNode,
          enabled: enabled,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          validator: controller.validateOtpCode,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          defaultPinTheme: basePinTheme,
          focusedPinTheme: basePinTheme.copyDecorationWith(
            border: Border.all(color: colorScheme.primary, width: 2),
          ),
          submittedPinTheme: basePinTheme.copyDecorationWith(
            border: Border.all(color: colorScheme.primary),
          ),
          errorPinTheme: basePinTheme.copyDecorationWith(
            border: Border.all(color: colorScheme.error),
          ),
        );
      },
    );
  }

  String _deliveryChannelLabel(String deliveryChannel) {
    return deliveryChannel ==
            AuthLoginControllerContract.phoneOtpDeliveryChannelSms
        ? 'SMS'
        : 'WhatsApp';
  }
}
