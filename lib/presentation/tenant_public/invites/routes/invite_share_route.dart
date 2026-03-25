import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/modular_app/modules/invites_module.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/invite_share_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'InviteShareRoute')
class InviteShareRoutePage extends StatelessWidget {
  const InviteShareRoutePage({
    super.key,
    this.invite,
  });

  final InviteModel? invite;

  @override
  Widget build(BuildContext context) {
    final resolvedInvite = invite;
    return ModuleScope<InvitesModule>(
      child: resolvedInvite == null
          ? Scaffold(
              appBar: AppBar(
                title: const Text('Compartilhar convite'),
              ),
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Convite indisponível',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Esta rota é interna e precisa de um convite carregado pelo fluxo de convite.',
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          context.router.replace(const InviteFlowRoute());
                        },
                        child: const Text('Ir para convites'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : InviteShareScreen(
              invite: resolvedInvite,
            ),
    );
  }
}
