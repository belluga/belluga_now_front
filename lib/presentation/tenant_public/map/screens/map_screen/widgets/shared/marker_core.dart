import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/shared/event_temporal_state.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/shared/marker_fallback_icon.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:flutter/material.dart';

class MarkerCore extends StatelessWidget {
  const MarkerCore({
    super.key,
    required this.event,
    required this.state,
    required this.activeColor,
    required this.size,
  });

  final EventModel event;
  final CityEventTemporalState state;
  final Color activeColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final primaryCounterpart = event.counterpartProfiles.isNotEmpty
        ? event.counterpartProfiles.first
        : null;
    final avatarUri = primaryCounterpart?.avatarUrl;
    final coverUri = primaryCounterpart?.coverUrl;
    final fallbackUri = event.thumb?.thumbUri.value.toString();
    final hasAvatar = avatarUri?.isNotEmpty ?? false;
    final hasCover = coverUri?.isNotEmpty ?? false;
    final imageUrl = hasAvatar
        ? avatarUri
        : (hasCover
            ? coverUri
            : ((fallbackUri?.isNotEmpty ?? false) ? fallbackUri : null));

    final decoration = BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.16),
          blurRadius: 5,
          offset: const Offset(0, 3),
        ),
      ],
    );

    return Container(
      width: size,
      height: size,
      decoration: decoration,
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null
          ? BellugaNetworkImage(
              imageUrl,
              fit: BoxFit.cover,
              errorWidget: MarkerFallbackIcon(color: activeColor),
            )
          : MarkerFallbackIcon(color: activeColor),
    );
  }
}
