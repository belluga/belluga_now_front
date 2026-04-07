import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/poi_base_card.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/shared/poi_content_resolver.dart';
import 'package:flutter/material.dart';

class EventPoiDetailCard extends PoiBaseCard {
  const EventPoiDetailCard({
    super.key,
    required super.poi,
    required super.colorScheme,
    required super.onPrimaryAction,
    required super.onShare,
    required super.onRoute,
  });

  @override
  Color resolveAccentColor() {
    if (poi.isHappeningNow) {
      return const Color(0xFFD93A56);
    }
    return super.resolveAccentColor();
  }

  @override
  List<Widget Function(BuildContext)> buildSections() => [
        _scheduleSection,
        _updatedAtSection,
        tagsSection,
      ];

  Widget _scheduleSection(BuildContext context) {
    final scheduleLabel = PoiContentResolver.eventScheduleLabel(poi);
    if (scheduleLabel == null) {
      return const SizedBox.shrink();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          poi.isHappeningNow ? Icons.bolt_rounded : Icons.schedule_rounded,
          size: 18,
          color: resolveAccentColor(),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            scheduleLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }

  Widget _updatedAtSection(BuildContext context) {
    final updatedAtLabel = PoiContentResolver.updatedAtLabel(poi);
    if (updatedAtLabel == null) {
      return const SizedBox.shrink();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          poi.isHappeningNow ? Icons.bolt_rounded : Icons.schedule_rounded,
          size: 18,
          color: resolveAccentColor(),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            updatedAtLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}
