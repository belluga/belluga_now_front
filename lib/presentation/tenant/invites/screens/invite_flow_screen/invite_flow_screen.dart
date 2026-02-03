import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/invites/invite_decision.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_flow_screen/controllers/invite_flow_controller.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_flow_screen/widgets/invite_flow_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class InviteFlowScreen extends StatefulWidget {
  const InviteFlowScreen({super.key});

  @override
  State<InviteFlowScreen> createState() => _InviteFlowScreenState();
}

class _InviteFlowScreenState extends State<InviteFlowScreen> {
  final InviteFlowScreenController _controller =
      GetIt.I.get<InviteFlowScreenController>();

  @override
  void initState() {
    super.initState();
    final inviteId = context.routeData.queryParams.get('invite');
    _controller.init(prioritizeInviteId: inviteId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<List<InviteModel>>(
      streamValue: _controller.pendingInvitesStreamValue,
      onNullWidget: const Center(child: CircularProgressIndicator()),
      builder: (context, invites) {
        return StreamValueBuilder<InviteDecisionResult?>(
          streamValue: _controller.decisionResultStreamValue,
          builder: (context, decisionResult) {
            return InviteFlowCoordinator(
              invites: invites,
              decisionResult: decisionResult,
            );
          },
        );
      },
    );
  }
}
