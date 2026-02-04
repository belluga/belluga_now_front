import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/presentation/tenant/partners/controllers/partner_detail_controller.dart';
import 'package:belluga_now/presentation/common/widgets/belluga_network_image.dart';
import 'package:belluga_now/presentation/common/widgets/immersive_detail_screen/immersive_detail_screen.dart';
import 'package:belluga_now/presentation/common/widgets/immersive_detail_screen/models/immersive_tab_item.dart';
import 'package:belluga_now/domain/partners/engagement_data.dart';
import 'package:belluga_now/domain/partners/projections/partner_profile_config.dart';
import 'package:belluga_now/domain/partners/projections/partner_profile_module_data.dart';
import 'package:belluga_now/application/icons/boora_icons.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:url_launcher/url_launcher.dart';

class PartnerDetailScreen extends StatefulWidget {
  const PartnerDetailScreen({
    super.key,
    required this.slug,
  });

  final String slug;

  @override
  State<PartnerDetailScreen> createState() => _PartnerDetailScreenState();
}

class _PartnerDetailScreenState extends State<PartnerDetailScreen> {
  final PartnerDetailController _controller =
      GetIt.I.get<PartnerDetailController>();

  @override
  void initState() {
    super.initState();
    _controller.loadPartner(widget.slug);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamValueBuilder<bool>(
        streamValue: _controller.isLoadingStreamValue,
        builder: (context, isLoading) {
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return StreamValueBuilder<AccountProfileModel?>(
            streamValue: _controller.partnerStreamValue,
            builder: (context, partner) {
              if (partner == null) {
                return const Center(child: Text('Parceiro não encontrado'));
              }
              return StreamValueBuilder<PartnerProfileConfig?>(
                streamValue: _controller.profileConfigStreamValue,
                builder: (context, config) {
                  if (config == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return StreamValueBuilder<Map<ProfileModuleId, Object?>>(
                    streamValue: _controller.moduleDataStreamValue,
                    builder: (context, moduleData) {
                      return StreamValueBuilder<Set<String>>(
                        streamValue: _controller.favoriteIdsStream,
                        builder: (context, favorites) {
                          final isFav = favorites.contains(partner.id);
                          final isFavoritable =
                              _controller.isFavoritable(partner);
                          final configTabs =
                              _buildTabsFromConfig(config, moduleData);
                          final screen = ImmersiveDetailScreen(
                            heroContent:
                                _buildHero(partner, isFav, isFavoritable),
                            title: partner.name,
                            tabs: configTabs,
                            betweenHeroAndTabs: _buildBetweenHero(partner),
                            footer: _buildFooter(partner, isFav, isFavoritable),
                          );
                          return Stack(
                            children: [
                              screen,
                              _buildMiniPlayer(),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHero(AccountProfileModel partner, bool isFav, bool isFavoritable) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        partner.coverUrl != null
            ? BellugaNetworkImage(
                partner.coverUrl!,
                fit: BoxFit.cover,
                errorWidget: Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    _iconForType(partner.type),
                    size: 64,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            : Container(
                color: colorScheme.surfaceContainerHighest,
                child: Icon(
                  _iconForType(partner.type),
                  size: 64,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
        Positioned(
          right: 16,
          top: 16,
          child: isFavoritable
              ? CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.6),
                  child: IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Colors.red : Colors.white,
                    ),
                    onPressed: () => _controller.toggleFavorite(partner.id),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Positioned(
          left: 16,
          bottom: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                partner.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text(_labelForType(partner.type)),
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    labelStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (partner.isVerified)
                    const Chip(
                      label: Text('Verificado'),
                      avatar:
                          Icon(Icons.verified, color: Colors.white, size: 16),
                      backgroundColor: Colors.green,
                      labelStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget? _buildBetweenHero(AccountProfileModel partner) {
    if (partner.tags.isEmpty && partner.engagementData == null) return null;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (partner.tags.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: partner.tags
                  .map((t) => Chip(
                        label: Text(t),
                        backgroundColor: colorScheme.secondaryContainer,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              _metricPill(BooraIcons.invite_solid,
                  partner.acceptedInvites.toString(), 'Convites aceitos'),
              if (partner.engagementData != null) ...[
                const SizedBox(width: 8),
                _metricPill(Icons.trending_up,
                    _engagementLabel(partner.engagementData!), 'Engajamento'),
              ],
            ],
          ),
        ],
      ),
    );
  }

  List<ImmersiveTabItem> _buildTabsFromConfig(
    PartnerProfileConfig config,
    Map<ProfileModuleId, Object?> moduleData,
  ) {
    return config.tabs
        .map(
          (tab) => ImmersiveTabItem(
            title: tab.title,
            content: _buildModules(tab.modules, moduleData),
            footer: _actionFooter('Seguir'),
          ),
        )
        .toList();
  }

  Widget _buildFooter(AccountProfileModel partner, bool isFav, bool isFavoritable) {
    if (!isFavoritable) return const SizedBox.shrink();
    return _actionFooter(isFav ? 'Favoritado' : 'Seguir');
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'artist':
        return Icons.music_note;
      case 'venue':
        return Icons.place;
      case 'experience_provider':
        return Icons.explore;
      case 'influencer':
        return Icons.person;
      case 'curator':
        return Icons.bookmark;
      default:
        return Icons.account_circle;
    }
  }

  String _labelForType(String type) {
    switch (type) {
      case 'artist':
        return 'Artista';
      case 'venue':
        return 'Local';
      case 'experience_provider':
        return 'Experiência';
      case 'influencer':
        return 'Conector';
      case 'curator':
        return 'Curador';
      default:
        return type;
    }
  }

  Widget _metricPill(IconData icon, String value, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _engagementLabel(EngagementData data) {
    switch (data) {
      case ArtistEngagementData():
        return data.status;
      case VenueEngagementData():
        return '${data.presenceCount} presenças';
      case ExperienceEngagementData():
        return '${data.experienceCount} exp.';
      case InfluencerEngagementData():
        return '${data.inviteCount} convites';
      case CuratorEngagementData():
        return '${data.articleCount + data.docCount} itens';
    }
    return '';
  }

  Widget _actionFooter(String label) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {},
          child: Text(label),
        ),
      ),
    );
  }

  // Placeholder module widgets
  Widget _artistHighlights(List<PartnerEventView>? events) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Destaques & Agenda',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (events == null || events.isEmpty)
            const Text('Nenhum evento disponível')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: events
                  .take(6)
                  .map(
                    (e) => Container(
                      width: 140,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            e.date,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _productGrid(List<PartnerProductView>? products) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: products?.length ?? 0,
        itemBuilder: (context, index) {
          final product = products![index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                      image: product.imageUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(product.imageUrl),
                              fit: BoxFit.cover,
                              onError: (_, __) {},
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(product.price),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _agendaList(List<PartnerEventView>? events) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: events == null || events.isEmpty
          ? const Text('Nenhum evento disponível')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: events
                  .map(
                    (e) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.event),
                        title: Text(e.title),
                        subtitle: Text('${e.date} • ${e.location}'),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _locationInfo(PartnerLocationView? location) {
    final mapPreviewUri = _buildMapPreviewUri(location);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.place),
            title: Text(location?.address ?? 'Endere??o n??o informado'),
            subtitle: Text(location?.status ?? ''),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _openMaps(location),
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade200,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (mapPreviewUri != null)
                    BellugaNetworkImage(
                      mapPreviewUri.toString(),
                      fit: BoxFit.cover,
                      errorWidget: _buildMapFallback(location),
                    )
                  else
                    _buildMapFallback(location),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.open_in_new, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openMaps(location),
              icon: const Icon(Icons.navigation),
              label: const Text('Tra??ar rota'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapFallback(PartnerLocationView? location) {
    final address = location?.address;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blueGrey.shade200,
            Colors.blueGrey.shade100,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: 32),
            const SizedBox(height: 6),
            Text(
              address?.isNotEmpty == true ? address! : 'Mapa do local',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Uri? _buildMapPreviewUri(PartnerLocationView? location) {
    if (location == null) return null;
    final lat = double.tryParse(location.lat ?? '');
    final lng = double.tryParse(location.lng ?? '');
    if (lat == null || lng == null) return null;
    return Uri.https(
      'staticmap.openstreetmap.de',
      '/staticmap.php',
      {
        'center': '$lat,$lng',
        'zoom': '15',
        'size': '640x360',
        'markers': '$lat,$lng,red-pushpin',
      },
    );
  }

  Future<void> _openMaps(PartnerLocationView? location) async {
    if (location == null) return;
    final lat = double.tryParse(location.lat ?? '');
    final lng = double.tryParse(location.lng ?? '');
    final hasCoords = lat != null && lng != null;
    final destination = hasCoords
        ? '$lat,$lng'
        : (location.address.isNotEmpty ? location.address : null);
    if (destination == null) return;

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(destination)}',
    );
    if (!await canLaunchUrl(uri)) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _experienceCards(List<PartnerExperienceView>? experiences) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: experiences == null || experiences.isEmpty
          ? const Text('Nenhuma experiência cadastrada')
          : Column(
              children: experiences
                  .map(
                    (e) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.explore),
                        title: Text(e.title),
                        subtitle: Text('${e.duration} • ${e.price}'),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _faqBlock(List<PartnerFaqView>? faq) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: faq == null || faq.isEmpty
          ? const Text('Nenhuma FAQ disponível')
          : ExpansionPanelList.radio(
              children: faq
                  .asMap()
                  .entries
                  .map(
                    (entry) => ExpansionPanelRadio(
                      value: entry.key,
                      headerBuilder: (context, _) =>
                          ListTile(title: Text(entry.value.question)),
                      body: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(entry.value.answer),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _videoGallery(List<PartnerMediaView>? videos) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: videos == null || videos.isEmpty
          ? const Text('Nenhum conteúdo no acervo')
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: videos
                  .map(
                    (v) => Container(
                      width: 160,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                        image: v.url.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(v.url),
                                fit: BoxFit.cover,
                                onError: (_, __) {},
                              )
                            : null,
                      ),
                      child: const Icon(Icons.play_arrow),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _externalLinks(List<PartnerLinkView>? links) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: links == null || links.isEmpty
          ? const Text('Nenhum link externo')
          : Column(
              children: links
                  .map(
                    (l) => Card(
                      child: ListTile(
                        leading: Icon(
                            l.icon == 'pix' ? Icons.pix : Icons.link_outlined),
                        title: Text(l.title),
                        subtitle: Text(l.subtitle),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _photoGrid(List<PartnerMediaView>? photos) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: photos == null || photos.isEmpty
          ? const Text('Nenhuma mídia')
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final photo = photos[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(6),
                    image: photo.url.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(photo.url),
                            fit: BoxFit.cover,
                            onError: (_, __) {},
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }

  Widget _affinityCarousel(List<PartnerRecommendationView>? recommendations) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recomendações',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (recommendations == null || recommendations.isEmpty)
            const Text('Nenhuma recomendação disponível')
          else
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recommendations.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final rec = recommendations[index];
                  return Container(
                    width: 160,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(rec.title),
                        Text(
                          rec.type,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black54),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _musicPlayer(List<PartnerMediaView>? tracks) {
    final track = tracks != null && tracks.isNotEmpty ? tracks.first : null;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.play_circle_fill),
          title: Text(track?.title ?? 'Faixa não disponível'),
          subtitle: Text(track?.url ?? ''),
          trailing: IconButton(
            icon: StreamValueBuilder<bool>(
              streamValue: _controller.isPlayingStreamValue,
              builder: (context, playing) {
                final current = _controller.currentTrackStreamValue.value;
                final isCurrent =
                    current != null && track != null && current.url == track.url;
                final icon =
                    isCurrent && playing ? Icons.pause : Icons.play_arrow;
                return Icon(icon);
              },
            ),
            onPressed: () {
              if (track != null) {
                _controller.playTrack(track);
              } else {
                _controller.togglePlayback();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _socialScore(PartnerScoreView? score) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(BooraIcons.invite_solid, size: 20),
          const SizedBox(width: 8),
          Text('${score?.invites ?? '--'} Convites Feitos'),
          const SizedBox(width: 16),
          const Icon(Icons.check_circle, size: 20),
          const SizedBox(width: 8),
          Text('${score?.presences ?? '--'} Presenças Reais'),
        ],
      ),
    );
  }

  Widget _supportedEntities(
      String title, List<PartnerSupportedEntityView>? data) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (data == null || data.isEmpty)
            const Text('Nenhum perfil apoiado')
          else
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: data.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final entity = data[index];
                  return Container(
                    width: 160,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: entity.thumb != null
                              ? BellugaNetworkImage(
                                  entity.thumb!,
                                  fit: BoxFit.cover,
                                  errorWidget: const SizedBox(),
                                )
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(entity.title),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _sponsorBanner(String? sponsor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.yellow.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.handshake),
            const SizedBox(width: 8),
            Expanded(
                child: Text('Oferecimento: ${sponsor ?? 'Parceiro local'}')),
          ],
        ),
      ),
    );
  }

  Widget _richTextBlock(String title, String body) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildModules(
    List<ProfileModuleConfig> modules,
    Map<ProfileModuleId, Object?> moduleData,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: modules.map((m) => _buildModule(m, moduleData[m.id])).toList(),
    );
  }

  Widget _buildModule(ProfileModuleConfig module, dynamic data) {
    switch (module.id) {
      case ProfileModuleId.socialScore:
        return _socialScore(data as PartnerScoreView?);
      case ProfileModuleId.agendaCarousel:
        return _artistHighlights(
          data is List<PartnerEventView> ? data : null,
        );
      case ProfileModuleId.agendaList:
        return _agendaList(
          data is List<PartnerEventView> ? data : null,
        );
      case ProfileModuleId.musicPlayer:
        return _musicPlayer(
          data is List<PartnerMediaView> ? data : null,
        );
      case ProfileModuleId.productGrid:
        return _productGrid(
          data is List<PartnerProductView> ? data : null,
        );
      case ProfileModuleId.photoGallery:
        return _photoGrid(
          data is List<PartnerMediaView> ? data : null,
        );
      case ProfileModuleId.videoGallery:
        return _videoGallery(
          data is List<PartnerMediaView> ? data : null,
        );
      case ProfileModuleId.experienceCards:
        return _experienceCards(
          data is List<PartnerExperienceView> ? data : null,
        );
      case ProfileModuleId.affinityCarousels:
        return _affinityCarousel(
          data is List<PartnerRecommendationView> ? data : null,
        );
      case ProfileModuleId.supportedEntities:
        return _supportedEntities(
          module.title ?? 'Quem apoiamos',
          data is List<PartnerSupportedEntityView> ? data : null,
        );
      case ProfileModuleId.richText:
        return _richTextBlock(
          module.title ?? 'Sobre',
          data is String
              ? data
              : 'Conteúdo institucional e história do parceiro.',
        );
      case ProfileModuleId.locationInfo:
        return _locationInfo(data as PartnerLocationView?);
      case ProfileModuleId.externalLinks:
        return _externalLinks(
          data is List<PartnerLinkView> ? data : null,
        );
      case ProfileModuleId.faq:
        return _faqBlock(
          data is List<PartnerFaqView> ? data : null,
        );
      case ProfileModuleId.sponsorBanner:
        return _sponsorBanner(data is String ? data : null);
    }
  }

  Widget _buildMiniPlayer() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: StreamValueBuilder<PartnerMediaView?>(
        streamValue: _controller.currentTrackStreamValue,
        builder: (context, track) {
          if (track == null) return const SizedBox.shrink();
          return SafeArea(
            child: Card(
              margin: const EdgeInsets.all(12),
              child: ListTile(
                leading: const Icon(Icons.music_note),
                title: Text(track.title ?? 'Faixa'),
                trailing: StreamValueBuilder<bool>(
                  streamValue: _controller.isPlayingStreamValue,
                  builder: (context, playing) {
                    return IconButton(
                      icon: Icon(
                          playing ? Icons.pause_circle : Icons.play_circle),
                      onPressed: () {
                        _controller.togglePlayback();
                      },
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
