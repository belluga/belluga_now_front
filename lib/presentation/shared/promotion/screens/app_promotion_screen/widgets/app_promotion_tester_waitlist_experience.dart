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
    final colorScheme = theme.colorScheme;
    final iconUrl = screenController.iconUrlForBrightness(theme.brightness);
    final title =
        'Teste o ${screenController.appDisplayName} antes do lançamento';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 24, 12, 24),
            child: Column(
              children: [
                _BrandIcon(
                  colorScheme: colorScheme,
                  iconUrl: iconUrl,
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  key: const Key('app_promotion_title'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Entre para o grupo piloto e receba as instruções no WhatsApp assim que abrirmos novos acessos.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                _BenefitsBlock(colorScheme: colorScheme),
                const SizedBox(height: 28),
                _FormCard(controller: controller),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextButton(
            key: const Key('app_promotion_dismiss_button'),
            onPressed: onDismiss,
            child: const Text('AGORA NÃO'),
          ),
        ),
      ],
    );
  }
}

class _BrandIcon extends StatelessWidget {
  const _BrandIcon({
    required this.colorScheme,
    required this.iconUrl,
  });

  final ColorScheme colorScheme;
  final String? iconUrl;

  @override
  Widget build(BuildContext context) {
    final iconChild = iconUrl == null
        ? Icon(
            Icons.auto_awesome_rounded,
            size: 40,
            color: colorScheme.onPrimaryContainer,
          )
        : BellugaNetworkImage(
            iconUrl!,
            width: 56,
            height: 56,
            fit: BoxFit.contain,
            errorWidget: Icon(
              Icons.auto_awesome_rounded,
              size: 40,
              color: colorScheme.onPrimaryContainer,
            ),
          );
    return Container(
      key: const Key('app_promotion_brand_icon'),
      width: 96,
      height: 96,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: iconChild,
    );
  }
}

class _BenefitsBlock extends StatelessWidget {
  const _BenefitsBlock({
    required this.colorScheme,
  });

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'O que você garante entrando agora',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          const _BenefitRow(label: 'Convite antecipado para o grupo piloto'),
          const SizedBox(height: 10),
          const _BenefitRow(label: 'Acesso gratuito para testar a experiência'),
          const SizedBox(height: 10),
          const _BenefitRow(
              label: 'Chance de influenciar os ajustes antes do MVP'),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_rounded,
          size: 18,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: StreamValueBuilder<bool>(
        streamValue: controller.submissionSucceededStreamValue,
        builder: (context, submissionSucceeded) {
          if (submissionSucceeded) {
            return Column(
              key: const Key('app_promotion_waitlist_success'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: colorScheme.primary,
                  size: 30,
                ),
                const SizedBox(height: 12),
                Text(
                  'Tudo pronto.',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Seu contato foi registrado. Se liberarmos novos acessos, vamos te avisar no WhatsApp.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quero ser testador',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Cadastre-se rápido e receba as próximas instruções.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              StreamValueBuilder<String?>(
                streamValue: controller.emailErrorStreamValue,
                builder: (context, emailError) {
                  return TextField(
                    key: const Key('app_promotion_waitlist_email_field'),
                    controller: controller.emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    onChanged: controller.onEmailChanged,
                    decoration: InputDecoration(
                      labelText: 'E-mail',
                      hintText: 'seu@email.com',
                      errorText: emailError,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              StreamValueBuilder<String?>(
                streamValue: controller.whatsappErrorStreamValue,
                builder: (context, whatsappError) {
                  return TextField(
                    key: const Key('app_promotion_waitlist_whatsapp_field'),
                    controller: controller.whatsappController,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                    onChanged: controller.onWhatsappChanged,
                    decoration: InputDecoration(
                      labelText: 'WhatsApp',
                      hintText: '27999999999',
                      errorText: whatsappError,
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              Text(
                'Qual o seu celular?',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              StreamValueBuilder<PromotionLeadMobilePlatform?>(
                streamValue: controller.selectedPlatformStreamValue,
                builder: (context, selectedPlatform) {
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ChoiceChip(
                        key: const Key('app_promotion_waitlist_platform_ios'),
                        label: const Text('iOS'),
                        avatar: const Icon(Icons.apple, size: 18),
                        selected:
                            selectedPlatform == PromotionLeadMobilePlatform.ios,
                        onSelected: (_) => controller.selectPlatform(
                          PromotionLeadMobilePlatform.ios,
                        ),
                      ),
                      ChoiceChip(
                        key: const Key(
                            'app_promotion_waitlist_platform_android'),
                        label: const Text('Android'),
                        avatar: const Icon(Icons.android, size: 18),
                        selected: selectedPlatform ==
                            PromotionLeadMobilePlatform.android,
                        onSelected: (_) => controller.selectPlatform(
                          PromotionLeadMobilePlatform.android,
                        ),
                      ),
                    ],
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(14),
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
                  return SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('app_promotion_waitlist_submit_button'),
                      onPressed: isSubmitting ? null : controller.submit,
                      child: Text(
                        isSubmitting ? 'Enviando...' : 'Quero ser testador',
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
