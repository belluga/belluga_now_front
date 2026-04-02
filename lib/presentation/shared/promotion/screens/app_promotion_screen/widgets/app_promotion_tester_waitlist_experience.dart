import 'package:belluga_now/domain/promotion/promotion_lead_mobile_platform.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/controllers/app_promotion_screen_controller.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/controllers/app_promotion_tester_waitlist_controller.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class AppPromotionTesterWaitlistExperience extends StatelessWidget {
  const AppPromotionTesterWaitlistExperience({
    super.key,
    required this.screenController,
    required this.controller,
    required this.onDismiss,
  });

  final AppPromotionScreenController screenController;
  final AppPromotionTesterWaitlistController controller;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconUrl = screenController.iconUrlForBrightness(theme.brightness);
    final title = 'Bora testar o ${screenController.appDisplayName}?';
    final description =
        'Faça parte da nossa comunidade exclusiva e ajude a moldar o futuro da experiência em ${screenController.appDisplayName}.';
    final successCopy =
        'Obrigado por querer construir o ${screenController.appDisplayName} com a gente. Agora é só aguardar que entraremos em contato em breve pelo WhatsApp ou E-mail.';

    return StreamValueBuilder<bool>(
      streamValue: controller.submissionSucceededStreamValue,
      builder: (context, submissionSucceeded) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
          child: submissionSucceeded
              ? _SuccessStateContent(
                  copy: successCopy,
                  onDismiss: onDismiss,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _WaitlistHero(
                      iconUrl: iconUrl,
                      title: title,
                      description: description,
                    ),
                    const SizedBox(height: 28),
                    _FormCard(controller: controller),
                    const SizedBox(height: 28),
                    const _BenefitsCarousel(),
                  ],
                ),
        );
      },
    );
  }
}

class _WaitlistHero extends StatelessWidget {
  const _WaitlistHero({
    required this.iconUrl,
    required this.title,
    required this.description,
  });

  final String? iconUrl;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        _HeroArtwork(iconUrl: iconUrl),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            title,
            key: const Key('app_promotion_title'),
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  height: 1.02,
                ) ??
                theme.textTheme.headlineMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  height: 1.02,
                ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroArtwork extends StatelessWidget {
  const _HeroArtwork({
    required this.iconUrl,
  });

  final String? iconUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageBorderRadius = BorderRadius.circular(38);

    return SizedBox(
      width: 148,
      height: 148,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: imageBorderRadius,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: iconUrl == null
                  ? Center(
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: 52,
                        color: colorScheme.primary,
                      ),
                    )
                  : BellugaNetworkImage(
                      iconUrl!,
                      width: 148,
                      height: 148,
                      fit: BoxFit.cover,
                      clipBorderRadius: imageBorderRadius,
                      errorWidget: Center(
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 52,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
            ),
          ),
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.star_rounded,
                color: colorScheme.onPrimary,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.controller,
  });

  final AppPromotionTesterWaitlistController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StreamValueBuilder<String?>(
            streamValue: controller.nameErrorStreamValue,
            builder: (context, nameError) {
              return _FieldGroup(
                label: 'Seu Nome',
                child: TextField(
                  key: const Key('app_promotion_waitlist_name_field'),
                  controller: controller.nameController,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  onChanged: controller.onNameChanged,
                  style: _fieldTextStyle(theme, colorScheme),
                  decoration: _pillInputDecoration(
                    context,
                    hintText: 'Como podemos te chamar?',
                    errorText: nameError,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          StreamValueBuilder<String?>(
            streamValue: controller.emailErrorStreamValue,
            builder: (context, emailError) {
              return _FieldGroup(
                label: 'E-mail',
                child: TextField(
                  key: const Key('app_promotion_waitlist_email_field'),
                  controller: controller.emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  onChanged: controller.onEmailChanged,
                  style: _fieldTextStyle(theme, colorScheme),
                  decoration: _pillInputDecoration(
                    context,
                    hintText: 'seu@email.com',
                    errorText: emailError,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          StreamValueBuilder<String?>(
            streamValue: controller.whatsappErrorStreamValue,
            builder: (context, whatsappError) {
              return _FieldGroup(
                label: 'WhatsApp',
                child: TextField(
                  key: const Key('app_promotion_waitlist_whatsapp_field'),
                  controller: controller.whatsappController,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  onChanged: controller.onWhatsappChanged,
                  style: _fieldTextStyle(theme, colorScheme),
                  decoration: _pillInputDecoration(
                    context,
                    hintText: '27999999999',
                    errorText: whatsappError,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Qual o seu sistema operacional?',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          StreamValueBuilder<PromotionLeadMobilePlatform?>(
            streamValue: controller.selectedPlatformStreamValue,
            builder: (context, selectedPlatform) {
              return Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _PlatformSegment(
                        key: const Key(
                          'app_promotion_waitlist_platform_android',
                        ),
                        label: 'Android',
                        selected: selectedPlatform ==
                            PromotionLeadMobilePlatform.android,
                        onTap: () => controller.selectPlatform(
                          PromotionLeadMobilePlatform.android,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _PlatformSegment(
                        key: const Key('app_promotion_waitlist_platform_ios'),
                        label: 'iOS',
                        selected:
                            selectedPlatform == PromotionLeadMobilePlatform.ios,
                        onTap: () => controller.selectPlatform(
                          PromotionLeadMobilePlatform.ios,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          StreamValueBuilder<String?>(
            streamValue: controller.platformErrorStreamValue,
            builder: (context, platformError) {
              final platformErrorText = platformError ?? '';
              if (platformErrorText.isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  platformErrorText,
                  key: const Key('app_promotion_waitlist_platform_error'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          StreamValueBuilder<String?>(
            streamValue: controller.expectationsErrorStreamValue,
            builder: (context, expectationsError) {
              return _FieldGroup(
                label:
                    'O que não pode faltar para atender às suas expectativas?',
                child: TextField(
                  key: const Key('app_promotion_waitlist_expectations_field'),
                  controller: controller.expectationsController,
                  minLines: 4,
                  maxLines: 6,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: controller.onExpectationsChanged,
                  style: _fieldTextStyle(theme, colorScheme),
                  decoration: _messageInputDecoration(
                    context,
                    hintText: 'Conte para nós o que você espera ver...',
                    errorText: expectationsError,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          StreamValueBuilder<String?>(
            streamValue: controller.submissionErrorMessageStreamValue,
            builder: (context, submissionErrorMessage) {
              final submissionErrorText = submissionErrorMessage ?? '';
              if (submissionErrorText.isEmpty) {
                return const SizedBox.shrink();
              }
              return Container(
                key: const Key('app_promotion_waitlist_error'),
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  submissionErrorText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
          StreamValueBuilder<bool>(
            streamValue: controller.isSubmittingStreamValue,
            builder: (context, isSubmitting) {
              return FilledButton(
                key: const Key('app_promotion_waitlist_submit_button'),
                onPressed: isSubmitting ? null : controller.submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 58),
                  shape: const StadiumBorder(),
                  textStyle: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: Text(
                  isSubmitting ? 'Enviando...' : 'Quero participar!',
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FieldGroup extends StatelessWidget {
  const _FieldGroup({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _PlatformSegment extends StatelessWidget {
  const _PlatformSegment({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _BenefitCardData {
  const _BenefitCardData({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;
}

class _BenefitsCarousel extends StatelessWidget {
  const _BenefitsCarousel();

  static const _items = <_BenefitCardData>[
    _BenefitCardData(
      icon: Icons.lock_open_rounded,
      title: 'Acesso\nantecipado',
    ),
    _BenefitCardData(
      icon: Icons.workspace_premium_rounded,
      title: 'Badges\nexclusivos',
    ),
    _BenefitCardData(
      icon: Icons.forum_rounded,
      title: 'Feedback que\nmolda o produto',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final backgrounds = <Color>[
      colorScheme.secondaryContainer,
      colorScheme.primaryContainer,
      colorScheme.tertiaryContainer,
    ];
    final foregrounds = <Color>[
      colorScheme.onSecondaryContainer,
      colorScheme.onPrimaryContainer,
      colorScheme.onTertiaryContainer,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            constraints.maxWidth > 360 ? 164.0 : constraints.maxWidth * 0.44;

        return SizedBox(
          key: const Key('app_promotion_waitlist_benefits_carousel'),
          height: 184,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final item = _items[index];
              return Container(
                width: cardWidth,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: backgrounds[index % backgrounds.length],
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      size: 32,
                      color: foregrounds[index % foregrounds.length],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: foregrounds[index % foregrounds.length],
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SuccessStateContent extends StatelessWidget {
  const _SuccessStateContent({
    required this.copy,
    required this.onDismiss,
  });

  final String copy;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      key: const Key('app_promotion_waitlist_success'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 18, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SuccessBadge(),
          const SizedBox(height: 34),
          Text(
            'Inscrição Enviada!',
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                  height: 1.02,
                ) ??
                theme.textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                  height: 1.02,
                ),
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              copy,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 36),
          FilledButton(
            key: const Key('app_promotion_waitlist_continue_button'),
            onPressed: onDismiss,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 58),
              shape: const StadiumBorder(),
              textStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            child: const Text('Continuar navegando'),
          ),
        ],
      ),
    );
  }
}

class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.34),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              size: 56,
              color: colorScheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

TextStyle? _fieldTextStyle(ThemeData theme, ColorScheme colorScheme) {
  return theme.textTheme.bodyLarge?.copyWith(
    color: colorScheme.onSurface,
    fontWeight: FontWeight.w500,
  );
}

InputDecoration _pillInputDecoration(
  BuildContext context, {
  required String hintText,
  required String? errorText,
}) {
  final colorScheme = Theme.of(context).colorScheme;

  OutlineInputBorder borderFor(Color color, {double width = 0}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(999),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    hintText: hintText,
    errorText: errorText,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
    enabledBorder: borderFor(Colors.transparent),
    disabledBorder: borderFor(Colors.transparent),
    focusedBorder: borderFor(colorScheme.primary, width: 2),
    errorBorder: borderFor(colorScheme.error, width: 1.5),
    focusedErrorBorder: borderFor(colorScheme.error, width: 2),
  );
}

InputDecoration _messageInputDecoration(
  BuildContext context, {
  required String hintText,
  required String? errorText,
}) {
  final colorScheme = Theme.of(context).colorScheme;

  OutlineInputBorder borderFor(Color color, {double width = 0}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    hintText: hintText,
    errorText: errorText,
    alignLabelWithHint: true,
    contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
    enabledBorder: borderFor(Colors.transparent),
    disabledBorder: borderFor(Colors.transparent),
    focusedBorder: borderFor(colorScheme.primary, width: 2),
    errorBorder: borderFor(colorScheme.error, width: 1.5),
    focusedErrorBorder: borderFor(colorScheme.error, width: 2),
  );
}
