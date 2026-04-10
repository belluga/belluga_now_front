import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/route_back_reentrancy_key.dart';
import 'package:belluga_now/application/router/support/tenant_public_safe_back.dart';
import 'package:belluga_now/presentation/shared/widgets/route_back_scope.dart';
import 'package:flutter/material.dart';

class TenantPrivacyPolicyScreen extends StatelessWidget {
  const TenantPrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backPolicy = buildTenantPublicSafeBackPolicy(
      context.router,
      fallbackRoute: const TenantHomeRoute(),
      reentrancyKey: resolveRouteBackReentrancyKey(
        context,
        fallbackRouteName: TenantPrivacyPolicyRoute.name,
      ),
    );

    return RouteBackScope(
      backPolicy: backPolicy,
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: backPolicy.handleBack),
          title: const Text('Política de privacidade'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Última atualização: 16/03/2026',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Text(
                  'Resumo',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Esta política descreve, de forma inicial, como tratamos dados '
                  'pessoais no Belluga Now (tenant Guarappari).',
                ),
                const SizedBox(height: 16),
                Text(
                  '1. Dados coletados',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Podemos coletar dados de cadastro, dados de uso do app, '
                  'dados de confirmação de presença em eventos e permissões '
                  'concedidas no dispositivo (como contatos, quando aplicável).',
                ),
                const SizedBox(height: 16),
                Text(
                  '2. Finalidade de uso',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Usamos os dados para autenticação, funcionamento das '
                  'funcionalidades sociais, confirmação de presença, segurança '
                  'da conta e melhoria da experiência.',
                ),
                const SizedBox(height: 16),
                Text(
                  '3. Compartilhamento',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Não vendemos dados pessoais. O compartilhamento com terceiros '
                  'ocorre apenas quando necessário para operação do serviço, '
                  'cumprimento legal ou proteção da plataforma.',
                ),
                const SizedBox(height: 16),
                Text(
                  '4. Direitos do usuário',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Você pode solicitar atualização ou exclusão de dados pessoais '
                  'conforme a legislação aplicável. Esta política pode ser '
                  'atualizada para refletir novos recursos e requisitos legais.',
                ),
                const SizedBox(height: 16),
                Text(
                  '5. Contato',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Dúvidas sobre privacidade podem ser enviadas para os canais '
                  'oficiais de suporte do tenant.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
