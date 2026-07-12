import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/support/route_redirect_path.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/presentation/shared/web/public_page_metadata.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_flow_screen/controllers/invite_flow_controller.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_flow_screen/invite_flow_page_metadata.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_flow_screen/widgets/invite_flow_coordinator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class InviteFlowScreen extends StatefulWidget {
  const InviteFlowScreen({super.key});

  @override
  State<InviteFlowScreen> createState() => _InviteFlowScreenState();
}

class _InviteFlowScreenState extends State<InviteFlowScreen> {
  final InviteFlowScreenController _controller = GetIt.I
      .get<InviteFlowScreenController>();
  bool _trackedWebLanding = false;
  StreamSubscription<List<InviteModel>>? _inviteMetadataSubscription;
  String? _lastMetadataFingerprint;

  @override
  void initState() {
    super.initState();
    final redirectPath = buildRedirectPathFromRouteMatch(
      context.routeData.route,
    );
    final inviteId = context.routeData.queryParams.get('invite');
    final shareCode = context.routeData.queryParams.get('code');
    _controller.init(
      prioritizeInviteId: inviteId,
      shareCode: shareCode,
      redirectPath: redirectPath,
    );
    _inviteMetadataSubscription = _controller.displayInvitesStreamValue.stream
        .listen(_syncWebMetadata);
    _syncWebMetadata(_controller.displayInvitesStreamValue.value);
    _trackWebInviteLanding(shareCode);
  }

  @override
  void dispose() {
    _inviteMetadataSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<List<InviteModel>>(
      streamValue: _controller.displayInvitesStreamValue,
      onNullWidget: const Center(child: CircularProgressIndicator()),
      builder: (context, invites) {
        return StreamValueBuilder<bool>(
          streamValue: _controller.authRequiredForDecisionStreamValue,
          builder: (context, requiresAuthentication) {
            return StreamValueBuilder<bool>(
              streamValue: _controller.initializedStreamValue,
              builder: (context, isInitialized) {
                return StreamValueBuilder<InviteDecisionResult?>(
                  streamValue: _controller.decisionResultStreamValue,
                  builder: (context, decisionResult) {
                    return InviteFlowCoordinator(
                      invites: invites,
                      decisionResult: decisionResult,
                      requiresAuthentication: requiresAuthentication,
                      isInitialized: isInitialized,
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

  void _trackWebInviteLanding(String? shareCode) {
    if (!kIsWeb || _trackedWebLanding) {
      return;
    }
    _trackedWebLanding = true;
    unawaited(_controller.trackWebLanding(shareCode));
  }

  void _syncWebMetadata(List<InviteModel> invites) {
    if (!kIsWeb || invites.isEmpty) {
      return;
    }

    final payload = buildInviteFlowPageMetadata(
      invite: invites.first,
      currentUrl: Uri.base,
      tenantName: _controller.tenantName,
    );
    final nextFingerprint =
        '${payload.title}|${payload.description}|${payload.url}|${payload.imageUrl ?? ''}';
    if (_lastMetadataFingerprint == nextFingerprint) {
      return;
    }
    _lastMetadataFingerprint = nextFingerprint;
    applyPublicPageMetadata(payload);
  }
}
