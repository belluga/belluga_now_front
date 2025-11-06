import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/presentation/tenant/mercado/data/mock_data/mock_mercado_data.dart';
import 'package:belluga_now/presentation/tenant/mercado/models/mercado_producer.dart';
import 'package:belluga_now/presentation/tenant/mercado/screens/producer_store_screen/producer_store_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InviteCard extends StatelessWidget {
  const InviteCard({
    super.key,
    required this.invite,
    this.isPreview = false,
    this.isTopOfDeck = true,
  });

  final InviteModel invite;
  final bool isPreview;
  final bool isTopOfDeck;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatter = DateFormat('EEE, d MMM - HH:mm');
    final formattedDate = dateFormatter.format(invite.eventDateTime.toLocal());
    final hasInviter = invite.inviters.isNotEmpty ||
        (invite.inviterName?.isNotEmpty ?? false) ||
        invite.additionalInviters.isNotEmpty;

    return SizedBox.expand(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasInviter && isTopOfDeck)
            _InviterBanner(invite: invite, isPreview: isPreview),
          if (hasInviter && isTopOfDeck) const SizedBox(height: 8),
          Expanded(
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      invite.eventImageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.2),
                            Colors.black.withValues(
                              alpha: isPreview ? 0.6 : 0.8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    left: 20,
                    right: 20,
                    child: _Header(
                      hostName: invite.hostName,
                      formattedDate: formattedDate,
                      location: invite.location,
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: _Footer(
                      eventName: invite.eventName,
                      message: invite.message,
                      tags: invite.tags,
                      theme: theme,
                      isPreview: isPreview,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InviterBanner extends StatelessWidget {
  const _InviterBanner({
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
}

class _Header extends StatelessWidget {
  const _Header({
    required this.hostName,
    required this.formattedDate,
    required this.location,
  });

  final String hostName;
  final String formattedDate;
  final String location;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Chip(
          avatar: const Icon(
            Icons.handshake_outlined,
            size: 16,
          ),
          label: Text(
            hostName,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
          backgroundColor: theme.colorScheme.secondaryContainer,
          shape: const StadiumBorder(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.calendar_month, size: 16, color: Colors.white70),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                formattedDate,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.place_outlined, size: 16, color: Colors.white70),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                location,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.avatarUrl,
    required this.placeholderText,
    this.radius = 10,
  });

  final String? avatarUrl;
  final String placeholderText;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
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

class _Footer extends StatelessWidget {
  const _Footer({
    required this.eventName,
    required this.message,
    required this.tags,
    required this.theme,
    required this.isPreview,
  });

  final String eventName;
  final String message;
  final List<String> tags;
  final ThemeData theme;
  final bool isPreview;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eventName,
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isPreview ? Colors.white60 : Colors.white70,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags
              .map(
                (tag) => Chip(
                  label: Text('#$tag'),
                  backgroundColor: Colors.black.withValues(alpha: 0.35),
                  shape: const StadiumBorder(),
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              )
              .toList(),
        ),
      ],
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

  factory _InviteSummary.fromInviter(InviteInviter inviter) {
    return _InviteSummary(
      name: inviter.name,
      type: inviter.type,
      avatarUrl: inviter.avatarUrl,
      partner: inviter.partner,
    );
  }

  final String name;
  final InviteInviterType type;
  final String? avatarUrl;
  final InvitePartnerSummary? partner;
}

MercadoProducer? _findMercadoProducer(String id) {
  try {
    return mockMercadoProducers.firstWhere((producer) => producer.id == id);
  } catch (_) {
    return null;
  }
}
