import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/poi_base_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  bool emphasizePrimaryAction(BuildContext context) => true;

  @override
  String primaryActionLabel(BuildContext context) =>
      poi.isHappeningNow ? 'Ver evento' : 'Abrir evento';

  @override
  String routeActionLabel(BuildContext context) => 'Como chegar';

  @override
  String badgeLabel(BuildContext context) =>
      poi.isHappeningNow ? 'Ao vivo' : 'Evento';

  @override
  Color resolveAccentColor() {
    if (poi.isHappeningNow) {
      return const Color(0xFFD93A56);
    }
    return super.resolveAccentColor();
  }

  @override
  List<Widget Function(BuildContext)> buildSections() => [
        addressSection,
        _eventStatusSection,
        tagsSection,
      ];

  Widget _eventStatusSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final updatedAt = poi.updatedAt;
    final supportingText = poi.isHappeningNow
        ? 'Programação ativa agora na sua região.'
        : updatedAt == null
            ? 'Programação confirmada pela curadoria local.'
            : 'Atualizado em ${DateFormat('dd/MM • HH:mm').format(updatedAt)}.';

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
            supportingText,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: poi.isHappeningNow ? FontWeight.w600 : null,
            ),
          ),
        ),
      ],
    );
  }
}
