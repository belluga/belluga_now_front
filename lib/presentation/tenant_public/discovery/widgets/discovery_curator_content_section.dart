import 'package:belluga_now/presentation/tenant_public/discovery/models/curator_content.dart';
import 'package:belluga_now/presentation/tenant_public/discovery/widgets/curator_content_card.dart';
import 'package:belluga_now/presentation/tenant_public/widgets/section_header.dart';
import 'package:flutter/material.dart';

class DiscoveryCuratorContentSection extends StatelessWidget {
  const DiscoveryCuratorContentSection({
    super.key,
    required this.contents,
  });

  final List<CuratorContent> contents;

  @override
  Widget build(BuildContext context) {
    if (contents.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: SectionHeader(
            title: 'Veja isso (curadores)',
            onPressed: () {},
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final content = contents[index];
              return SizedBox(
                width: 220,
                child: CuratorContentCard(content: content),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: contents.length,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
