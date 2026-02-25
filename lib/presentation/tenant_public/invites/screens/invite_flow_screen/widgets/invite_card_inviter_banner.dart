import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/invites/invite_inviter.dart';
import 'package:belluga_now/domain/invites/invite_inviter_type.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_partner_summary.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_flow_screen/widgets/invite_summary_avatar.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_flow_screen/widgets/inviter_name_label.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_flow_screen/widgets/partner_fallback.dart';
import 'package:flutter/material.dart';

class InviteCardInviterBanner extends StatelessWidget {
  const InviteCardInviterBanner({
    super.key,
    required this.invite,
    required this.isPreview,
  });

  final InviteModel invite;
  final bool isPreview;

  @override
  Widget build(BuildContext context) {
    final inviters = _resolveInviters();
    if (inviters.isEmpty) {
      return const SizedBox.shrink();
    }

    final primary = inviters.first;
    final others =
        inviters.length > 1 ? inviters.sublist(1) : <_InviteSummary>[];
    final theme = Theme.of(context);
    final avatarUrl = primary.avatarUrl ??
        primary.partner?.logoImageUrl ??
        primary.partner?.heroImageUrl;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      color: theme.colorScheme.surface.withValues(alpha: 0.95),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Voce foi convidado por',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              InviterNameLabel(
                name: primary.name,
                partner: primary.partner,
                isPreview: isPreview,
                onTapPartner: primary.partner != null && !isPreview
                    ? () => _showPartnerSheet(context, primary.partner!)
                    : null,
              ),
              InviteSummaryAvatar(
                avatarUrl: avatarUrl,
                placeholderText: primary.name.isNotEmpty
                    ? primary.name[0].toUpperCase()
                    : '?',
              ),
              if (others.isNotEmpty)
                GestureDetector(
                  onTap: isPreview
                      ? null
                      : () => _showInvitersDialog(context, inviters),
                  child: Text(
                    'e mais ${others.length}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      decoration: isPreview
                          ? TextDecoration.none
                          : TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showInvitersDialog(
    BuildContext context,
    List<_InviteSummary> inviters,
  ) async {
    if (inviters.isEmpty) {
      return;
    }

    final router = context.router;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Quem convidou'),
        content: SizedBox(
          width: 320,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: ListView.builder(
              itemCount: inviters.length,
              itemBuilder: (context, index) {
                final summary = inviters[index];
                return ListTile(
                  leading: InviteSummaryAvatar(
                    avatarUrl: summary.avatarUrl ??
                        summary.partner?.logoImageUrl ??
                        summary.partner?.heroImageUrl,
                    placeholderText: summary.name.isNotEmpty
                        ? summary.name[0].toUpperCase()
                        : '?',
                    radius: 18,
                  ),
                  title: Text(summary.name),
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  onTap: summary.partner != null && !isPreview
                      ? () {
                          router.pop();
                          _showPartnerSheet(context, summary.partner!);
                        }
                      : null,
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => router.pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  List<_InviteSummary> _resolveInviters() {
    if (invite.inviters.isNotEmpty) {
      return invite.inviters
          .map(_InviteSummary.fromInviter)
          .where((summary) => summary.name.isNotEmpty)
          .toList();
    }

    final fallback = <_InviteSummary>[];
    if (invite.inviterName != null && invite.inviterName!.isNotEmpty) {
      fallback.add(
        _InviteSummary(
          name: invite.inviterName!,
          type: InviteInviterType.user,
          avatarUrl: invite.inviterAvatarUrl,
        ),
      );
    }
    fallback.addAll(
      invite.additionalInviters.where((name) => name.isNotEmpty).map(
            (name) => _InviteSummary(
              name: name,
              type: InviteInviterType.user,
            ),
          ),
    );
    return fallback;
  }

  Future<void> _showPartnerSheet(
    BuildContext context,
    InvitePartnerSummary partner,
  ) async {
    Widget sheetContent = PartnerFallbackView(name: partner.name);
    final router = context.router;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.9,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            child: Stack(
              children: [
                Positioned.fill(child: sheetContent),
                Positioned(
                  top: 8,
                  right: 8,
                    child: SafeArea(
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => router.pop(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InviteSummary {
  _InviteSummary({
    required this.name,
    required this.type,
    this.avatarUrl,
    this.partner,
  });

  final String name;
  final InviteInviterType type;
  final String? avatarUrl;
  final InvitePartnerSummary? partner;

  factory _InviteSummary.fromInviter(InviteInviter inviter) {
    return _InviteSummary(
      name: inviter.name,
      type: inviter.type,
      avatarUrl: inviter.avatarUrl,
      partner: inviter.partner,
    );
  }
}
