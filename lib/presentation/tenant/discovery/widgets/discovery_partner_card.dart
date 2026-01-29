import 'package:belluga_now/domain/partners/engagement_data.dart';
import 'package:belluga_now/domain/partners/partner_model.dart';
import 'package:belluga_now/application/icons/boora_icons.dart';
import 'package:flutter/material.dart';

class DiscoveryPartnerCard extends StatefulWidget {
  const DiscoveryPartnerCard({
    super.key,
    required this.partner,
    required this.isFavorite,
    required this.isFavoritable,
    required this.onFavoriteTap,
    required this.onTap,
    this.showDetails = true,
  });

  final PartnerModel partner;
  final bool isFavorite;
  final bool isFavoritable;
  final VoidCallback onFavoriteTap;
  final VoidCallback onTap;
  final bool showDetails;

  @override
  State<DiscoveryPartnerCard> createState() => _DiscoveryPartnerCardState();
}

class _DiscoveryPartnerCardState extends State<DiscoveryPartnerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLiveNow = widget.partner.engagementData is ArtistEngagementData &&
        (widget.partner.engagementData as ArtistEngagementData)
            .status
            .contains('AGORA');

    return LayoutBuilder(
      builder: (context, constraints) {
        final targetWidth = MediaQuery.of(context).size.width * 0.8;
        final isFullSize = constraints.maxWidth >= targetWidth * 0.8;
        final height = constraints.maxWidth * 9 / 16;

        return SizedBox(
          width: constraints.maxWidth,
          height: height,
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.partner.avatarUrl != null)
                    Image.network(
                      widget.partner.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            _getPartnerIcon(widget.partner.type),
                            size: 48,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(
                        _getPartnerIcon(widget.partner.type),
                        size: 48,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.partner.distanceMeters != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.place,
                                    size: 14, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  widget.partner.distanceMeters! >= 1000
                                      ? '${(widget.partner.distanceMeters! / 1000).toStringAsFixed(1)} km'
                                      : '${widget.partner.distanceMeters!.toStringAsFixed(0)} m',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (widget.isFavoritable)
                              CircleAvatar(
                                radius: 18,
                                backgroundColor:
                                    Colors.black.withValues(alpha: 0.5),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  iconSize: 22,
                                  icon: Icon(
                                    widget.isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: widget.isFavorite
                                        ? Colors.red
                                        : Colors.white,
                                  ),
                                  onPressed: widget.onFavoriteTap,
                                ),
                              ),
                            if (widget.isFavoritable) const SizedBox(height: 8),
                            _buildMetricChip(
                              BooraIcons.invite_solid,
                              widget.partner.acceptedInvites.toString(),
                              'Convites aceitos',
                            ),
                            if (widget.partner.engagementData != null)
                              ..._buildOptionalMetric(
                                  widget.partner.engagementData!),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: isFullSize && widget.showDetails
                        ? AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            switchInCurve: Curves.easeOut,
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                              opacity: animation,
                              child: SizeTransition(
                                sizeFactor: animation,
                                axisAlignment: -1,
                                child: child,
                              ),
                            ),
                            child: Padding(
                              key: const ValueKey('details'),
                              padding: const EdgeInsets.all(12),
                              child: _buildDetails(isLiveNow),
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('empty-details')),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.8),
                              Colors.black.withValues(alpha: 0.45),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.55, 1.0],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetails(bool isLiveNow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              _getPartnerLabel(widget.partner.type),
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isLiveNow) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: const Icon(
                            Icons.music_note,
                            size: 10,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      'TOCANDO AGORA',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                widget.partner.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3,
                      color: Colors.black45,
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.partner.isVerified) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.verified,
                size: 18,
                color: Colors.blue,
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        if (widget.partner.tags.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 48),
            child: Wrap(
              spacing: 4,
              runSpacing: 2,
              children: widget.partner.tags
                  .take(4)
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        const SizedBox(height: 6),
        _buildMetricRow(),
      ],
    );
  }

  Widget _buildMetricRow() {
    final chips = <Widget>[
      _buildMetricChip(
        BooraIcons.invite_solid,
        widget.partner.acceptedInvites.toString(),
        'Convites aceitos',
      ),
    ];

    chips.addAll(_buildOptionalMetric(widget.partner.engagementData));

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: chips,
    );
  }

  Widget _buildMetricChip(IconData icon, String value, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOptionalMetric(EngagementData? data) {
    if (data == null) return const [];
    switch (data) {
      case ArtistEngagementData():
        return const [];
      case VenueEngagementData():
        return [
          const SizedBox(width: 6),
          _buildMetricChip(
            Icons.check_circle,
            data.presenceCount.toString(),
            'Presenças confirmadas',
          ),
        ];
      case InfluencerEngagementData():
        return const [];
      case CuratorEngagementData():
        return [
          const SizedBox(width: 6),
          _buildMetricChip(
            Icons.explore,
            (data.articleCount + data.docCount).toString(),
            'Itens no acervo',
          ),
        ];
      case ExperienceEngagementData():
        return [
          const SizedBox(width: 6),
          _buildMetricChip(
            Icons.local_activity,
            data.experienceCount.toString(),
            'Experiências oferecidas',
          ),
        ];
    }
    return const [];
  }
}

IconData _getPartnerIcon(PartnerType type) {
  switch (type) {
    case PartnerType.artist:
      return Icons.person;
    case PartnerType.venue:
      return Icons.place;
    case PartnerType.experienceProvider:
      return Icons.local_activity;
    case PartnerType.influencer:
      return Icons.camera_alt;
    case PartnerType.curator:
      return Icons.verified_user;
  }
}

String _getPartnerLabel(PartnerType type) {
  switch (type) {
    case PartnerType.artist:
      return 'Artista';
    case PartnerType.venue:
      return 'Local';
    case PartnerType.experienceProvider:
      return 'Experiência';
    case PartnerType.influencer:
      return 'Influenciador';
    case PartnerType.curator:
      return 'Curador';
  }
}
