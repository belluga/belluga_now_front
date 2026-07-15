import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/auth/account_deletion_journey_state.dart';
import 'package:belluga_now/presentation/tenant_public/profile/screens/account_deletion_resolution_screen/controllers/account_deletion_resolution_controller.dart';
import 'package:belluga_now/presentation/tenant_public/profile/screens/account_deletion_resolution_screen/controllers/account_deletion_resolution_ui_phase.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class AccountDeletionResolutionScreen extends StatefulWidget {
  const AccountDeletionResolutionScreen({super.key});

  @override
  State<AccountDeletionResolutionScreen> createState() =>
      _AccountDeletionResolutionScreenState();
}

class _AccountDeletionResolutionScreenState
    extends State<AccountDeletionResolutionScreen> {
  final AccountDeletionResolutionController _controller = GetIt.I
      .get<AccountDeletionResolutionController>();
  StreamSubscription<int>? _tenantPublicNavigationSubscription;

  @override
  void initState() {
    super.initState();
    _tenantPublicNavigationSubscription = _controller
        .tenantPublicNavigationRequestStreamValue
        .stream
        .listen(_handleTenantPublicNavigation);
  }

  @override
  void dispose() {
    _tenantPublicNavigationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Conta'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: StreamValueBuilder<AccountDeletionJourneyState>(
              streamValue: _controller.journeyStreamValue,
              builder: (context, journey) {
                return StreamValueBuilder<AccountDeletionResolutionUiPhase>(
                  streamValue: _controller.uiPhaseStreamValue,
                  builder: (context, uiPhase) {
                    if (journey.phase ==
                        AccountDeletionJourneyPhase.confirmed) {
                      return _buildConfirmed(theme, uiPhase);
                    }
                    if (journey.phase == AccountDeletionJourneyPhase.unknown) {
                      return _buildUnknown(theme, uiPhase);
                    }
                    return const SizedBox.shrink();
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmed(
    ThemeData theme,
    AccountDeletionResolutionUiPhase uiPhase,
  ) {
    final isContinuing = uiPhase == AccountDeletionResolutionUiPhase.continuing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Conta removida',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Sua conta e os dados vinculados foram removidos permanentemente.',
        ),
        if (uiPhase == AccountDeletionResolutionUiPhase.exitGuidance) ...[
          const SizedBox(height: 12),
          const Text('Você pode fechar o app pelo sistema quando quiser.'),
        ],
        if (uiPhase == AccountDeletionResolutionUiPhase.continuationFailed) ...[
          const SizedBox(height: 12),
          Text(
            'Não foi possível iniciar o uso anônimo agora. Tente novamente.',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const Key('accountDeletionContinueAnonymousButton'),
            onPressed: isContinuing
                ? null
                : () => unawaited(_controller.continueAnonymously()),
            child: Text(
              isContinuing
                  ? 'Preparando uso anônimo...'
                  : 'Continuar de forma anônima',
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            key: const Key('accountDeletionExitAppButton'),
            onPressed: _controller.showExitGuidance,
            child: const Text('Sair do app'),
          ),
        ),
      ],
    );
  }

  Widget _buildUnknown(
    ThemeData theme,
    AccountDeletionResolutionUiPhase uiPhase,
  ) {
    final isReconciling =
        uiPhase == AccountDeletionResolutionUiPhase.reconciling;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Não foi possível confirmar a remoção',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Não vamos afirmar que a conta continua ativa nem que foi removida. Verifique novamente para confirmar a situação.',
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const Key('accountDeletionReconcileButton'),
            onPressed: isReconciling
                ? null
                : () => unawaited(_controller.reconcileUnknownOutcome()),
            child: Text(
              isReconciling ? 'Verificando...' : 'Verificar situação',
            ),
          ),
        ),
      ],
    );
  }

  void _handleTenantPublicNavigation(int request) {
    if (!mounted || request <= 0) {
      return;
    }
    unawaited(
      context.router.replaceAll(<PageRouteInfo>[const TenantHomeRoute()]),
    );
  }
}
