import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class EventInfoSection extends StatelessWidget {
  const EventInfoSection({
    required this.event,
    super.key,
  });

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final html = event.content.value?.trim() ?? '';
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16).copyWith(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sobre',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Html(
            data: html.isEmpty ? '<p>Sem descrição disponível.</p>' : html,
            style: {
              'body': Style(
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
                color: colorScheme.onSurfaceVariant,
                fontSize: FontSize(
                  Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16,
                ),
                lineHeight: const LineHeight(1.45),
              ),
              'p': Style(
                margin: Margins.only(bottom: 12),
              ),
              'strong': Style(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
              'br': Style(
                display: Display.block,
              ),
            },
          ),
        ],
      ),
    );
  }
}
