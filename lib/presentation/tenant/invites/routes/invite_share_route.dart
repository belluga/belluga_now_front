import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/invites_module.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_share_screen/invite_share_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'InviteShareRoute')
class InviteShareRoutePage extends StatelessWidget {
  const InviteShareRoutePage({
    super.key,
    required this.invite,
  });

  final InviteModel invite;

  @override
  Widget build(BuildContext context) {
    return ModuleScope<InvitesModule>(
      child: InviteShareScreen(
        invite: invite,
      ),
    );
  }
}
