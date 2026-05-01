import 'dart:async';

import 'package:belluga_now/application/configurations/widget_keys.dart';
import 'package:belluga_now/domain/auth/auth_phone_otp_challenge.dart';
import 'package:belluga_now/presentation/tenant_public/auth/login/controllers/auth_login_controller_contract.dart';
import 'package:belluga_form_validation/belluga_form_validation.dart';
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
    this.autoVerifyOnCodeComplete = false,
  });

  final AuthLoginControllerContract controller;
  final bool showOtpDestinationHeader;
  final bool showOtpSecondaryActions;
  final bool autoVerifyOnCodeComplete;

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
                  autoVerifyOnCodeComplete: autoVerifyOnCodeComplete,
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
      child: AnimatedBuilder(
        animation: controller.phoneNumberController,
        builder: (context, _) {
          final selectedCountry =
              controller.phoneNumberController.value.isoCode;

          return TextFormField(
            key: WidgetKeys.auth.loginPhoneField,
            controller: controller.phoneNationalNumberTextController,
            focusNode: controller.phoneFocusNode,
            enabled: enabled,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            textInputAction: TextInputAction.done,
            inputFormatters: [
              _CountryAwarePhoneInputFormatter(
                () => controller.phoneNumberController.value.isoCode,
              ),
            ],
            validator: controller.validatePhoneNationalInput,
            onChanged: controller.updatePhoneOtpNationalInput,
            onFieldSubmitted: (_) {
              if (enabled) {
                unawaited(controller.requestPhoneOtpChallenge());
              }
            },
            decoration: InputDecoration(
              labelText: 'Telefone',
              helperText: 'Selecione o país e informe o número.',
              prefixIcon: Padding(
                padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
                child: CountryButton(
                  isoCode: selectedCountry,
                  enabled: enabled,
                  onTap: enabled ? () => _selectCountry(context) : null,
                  showDialCode: true,
                  showFlag: true,
                  showIsoCode: true,
                  flagSize: 16,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
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
          );
        },
      ),
    );
  }

  Future<void> _selectCountry(BuildContext context) async {
    final selectedCountry =
        await const CountrySelectorNavigator.modalBottomSheet().show(context);
    if (selectedCountry == null) {
      return;
    }
    controller.updatePhoneOtpCountry(selectedCountry);
    controller.phoneFocusNode.requestFocus();
  }
}

class _CountryAwarePhoneInputFormatter extends TextInputFormatter {
  const _CountryAwarePhoneInputFormatter(this.countryResolver);

  final IsoCode Function() countryResolver;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.trim();
    if (raw.startsWith('+')) {
      return newValue;
    }

    final input = _isFormattingOnlyDeletion(oldValue, newValue)
        ? _removeDigitBeforeCursor(oldValue, newValue)
        : raw;
    final formatted =
        AuthLoginControllerContract.formatPhoneNationalDigitsForInput(
      countryResolver(),
      input,
    );
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static bool _isFormattingOnlyDeletion(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!oldValue.selection.isCollapsed || !newValue.selection.isCollapsed) {
      return false;
    }
    if (newValue.text.length >= oldValue.text.length) {
      return false;
    }
    return _digitsOnly(oldValue.text) == _digitsOnly(newValue.text);
  }

  static String _removeDigitBeforeCursor(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = _digitsOnly(oldValue.text);
    if (digits.isEmpty) {
      return '';
    }

    final cursorOffset = newValue.selection.baseOffset < 0
        ? newValue.text.length
        : newValue.selection.baseOffset;
    final oldPrefixEnd = cursorOffset.clamp(0, oldValue.text.length);
    var digitIndexBeforeCursor = -1;
    var currentDigitIndex = 0;

    for (var index = 0; index < oldValue.text.length; index += 1) {
      final character = oldValue.text[index];
      if (!_isDigit(character)) {
        continue;
      }
      if (index < oldPrefixEnd) {
        digitIndexBeforeCursor = currentDigitIndex;
      }
      currentDigitIndex += 1;
    }

    if (digitIndexBeforeCursor < 0) {
      return digits;
    }

    return digits.replaceRange(
      digitIndexBeforeCursor,
      digitIndexBeforeCursor + 1,
      '',
    );
  }

  static String _digitsOnly(String value) =>
      value.replaceAll(RegExp(r'\D'), '');

  static bool _isDigit(String character) =>
      character.codeUnitAt(0) >= 48 && character.codeUnitAt(0) <= 57;
}

class _OtpVerificationForm extends StatelessWidget {
  const _OtpVerificationForm({
    required this.controller,
    required this.enabled,
    required this.showDestinationHeader,
    required this.showSecondaryActions,
    required this.autoVerifyOnCodeComplete,
  });

  final AuthLoginControllerContract controller;
  final bool enabled;
  final bool showDestinationHeader;
  final bool showSecondaryActions;
  final bool autoVerifyOnCodeComplete;

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<AuthPhoneOtpChallenge?>(
      streamValue: controller.currentPhoneOtpChallengeStreamValue,
      builder: (context, challenge) {
        final phone =
            challenge?.phone ?? controller.phoneController.text.trim();
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
                                'Código enviado por '
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
              FormValidationFieldErrorBuilder(
                validationStreamValue: controller.phoneOtpValidationStreamValue,
                fieldId:
                    AuthLoginControllerContract.phoneOtpValidationTargetCode,
                builder: (context, errorText) {
                  return _buildOtpInput(theme, colorScheme, errorText);
                },
              ),
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
                      child: const Text('Reenviar código'),
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
      },
    );
  }

  void _requestNewCode() {
    unawaited(controller.resendPhoneOtpChallenge());
  }

  void _requestSmsCode() {
    unawaited(controller.requestPhoneOtpSmsChallenge());
  }

  Widget _buildOtpInput(
    ThemeData theme,
    ColorScheme colorScheme,
    String? errorText,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final normalizedErrorText = errorText?.trim();
        final hasBackendError =
            normalizedErrorText != null && normalizedErrorText.isNotEmpty;
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
          onChanged: (_) => controller.clearPhoneOtpCodeError(),
          onCompleted: autoVerifyOnCodeComplete
              ? (_) => unawaited(
                    controller.verifyPhoneOtpChallengeOnceOnCodeComplete(),
                  )
              : null,
          validator: controller.validateOtpCode,
          forceErrorState: hasBackendError,
          errorText: hasBackendError ? normalizedErrorText : null,
          errorTextStyle: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.error,
            height: 1.25,
          ),
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
