import 'package:belluga_now/domain/experiences/experience_model.dart';
import 'package:belluga_now/presentation/tenant/experiences/screens/experience_detail_screen/widgets/experience_detail_section.dart';
import 'package:flutter/material.dart';

class ExperienceDetailScreen extends StatelessWidget {
  const ExperienceDetailScreen({
    super.key,
    required this.experience,
  });

  final ExperienceModel experience;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 260,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(experience.title),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    experience.imageUrl ??
                        'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=900',
                    fit: BoxFit.cover,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
            sliver: SliverList.list(
              children: [
                ExperienceDetailSection(
                  title: 'Oferecido por',
                  child: Text(
                    experience.providerName,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (experience.priceLabel != null)
                  ExperienceDetailSection(
                    title: 'Investimento',
                    child: Text(
                      experience.priceLabel!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (experience.duration != null)
                  ExperienceDetailSection(
                    title: 'Duracao',
                    child: Text(experience.duration!),
                  ),
                if (experience.meetingPoint != null)
                  ExperienceDetailSection(
                    title: 'Ponto de encontro',
                    child: Text(experience.meetingPoint!),
                  ),
                ExperienceDetailSection(
                  title: 'Descricao',
                  child: Text(
                    experience.description,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                if (experience.tags.isNotEmpty)
                  ExperienceDetailSection(
                    title: 'Tags',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: experience.tags
                          .map(
                            (tag) => Chip(
                              label: Text(tag),
                              side: BorderSide(
                                color: theme.colorScheme.primary,
                              ),
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                if (experience.highlightItems.isNotEmpty)
                  ExperienceDetailSection(
                    title: 'Inclui',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: experience.highlightItems
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('- '),
                                  Expanded(child: Text(item)),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  'Conteudo mockado - tela de detalhe em fase de validacao.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Consultar via WhatsApp'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
          ),
        ),
      ),
    );
  }
}
