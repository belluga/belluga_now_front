import 'package:belluga_now/domain/invites/invite_inviter.dart';
import 'package:belluga_now/domain/invites/invite_inviter_type.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_partner_summary.dart';
import 'package:belluga_now/domain/invites/invite_partner_type.dart';
import 'package:belluga_now/presentation/tenant/mercado/data/mock_data/mock_mercado_data.dart';
import 'package:belluga_now/presentation/tenant/mercado/models/mercado_producer.dart';
import 'package:belluga_now/presentation/tenant/mercado/screens/producer_store_screen/producer_store_screen.dart';
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
              _InviterName(
                summary: primary,
                isPreview: isPreview,
                onTapPartner: primary.partner != null && !isPreview
                    ? () => _showPartnerSheet(context, primary.partner!)
                    : null,
              ),
              _Avatar(
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
                  leading: _Avatar(
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
                          Navigator.of(dialogContext).pop();
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
            onPressed: () => Navigator.of(dialogContext).pop(),
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
    Widget sheetContent;
    switch (partner.type) {
      case InvitePartnerType.mercadoProducer:
        final producer = _findMercadoProducer(partner.id);
        sheetContent = producer != null
            ? ProducerStoreScreen(producer: producer)
            : _PartnerFallback(name: partner.name);
        break;
    }

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
                      onPressed: () => Navigator.of(sheetContext).pop(),
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

  MercadoProducer? _findMercadoProducer(String partnerId) {
    return mockMercadoProducers.firstWhere(
      (producer) => producer.id == partnerId,
      orElse: () => mockMercadoProducers.first,
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.avatarUrl,
    required this.placeholderText,
    this.radius = 24,
  });

  final String? avatarUrl;
  final String placeholderText;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
      backgroundColor: Theme.of(context).colorScheme.surfaceTint,
      child: avatarUrl == null
          ? Text(
              placeholderText,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            )
          : null,
    );
  }
}

class _InviterName extends StatelessWidget {
  const _InviterName({
    required this.summary,
    required this.isPreview,
    this.onTapPartner,
  });

  final _InviteSummary summary;
  final bool isPreview;
  final VoidCallback? onTapPartner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = Text(
      summary.name,
      style: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      textAlign: TextAlign.center,
    );

    if (summary.partner != null && onTapPartner != null) {
      return Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: isPreview ? null : onTapPartner,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: text,
          ),
        ),
      );
    }

    return text;
  }
}

class _PartnerFallback extends StatelessWidget {
  const _PartnerFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Detalhes do parceiro $name indisponiveis no momento.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
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
