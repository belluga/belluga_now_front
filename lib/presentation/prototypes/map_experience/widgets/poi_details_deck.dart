import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/direction_info.dart';
import 'package:belluga_now/domain/map/event_poi_model.dart';
import 'package:belluga_now/domain/map/ride_share_option.dart';
import 'package:belluga_now/domain/map/ride_share_provider.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/infrastructure/repositories/poi_repository.dart';
import 'package:belluga_now/presentation/prototypes/map_experience/controllers/map_screen_controller.dart';
import 'package:belluga_now/presentation/prototypes/map_experience/widgets/poi_detail_card_builder.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/shared/poi_category_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:url_launcher/url_launcher.dart';

const double _kDeckMeasurementPadding = 32;

class PoiDetailDeck extends StatefulWidget {
  const PoiDetailDeck({super.key});

  @override
  State<PoiDetailDeck> createState() => _PoiDetailDeckState();
}

class _PoiDetailDeckState extends State<PoiDetailDeck>
    with TickerProviderStateMixin {
  final _controller = GetIt.I.get<MapScreenController>();
  final PageController _pageController = PageController(viewportFraction: 0.8);
  final PoiDetailCardBuilder _cardBuilder = const PoiDetailCardBuilder();
  int _pageIndex = 0;
  PoiFilterMode? _lastFilterMode;
  final Map<String, double> _poiHeights = <String, double>{};

  static const double _defaultCardHeight = 320;
  static const double _minCardHeight = 220;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return StreamValueBuilder<PoiFilterMode>(
      streamValue: _controller.filterModeStreamValue,
      builder: (_, mode) {
        if (_lastFilterMode != mode) {
          _lastFilterMode = mode;
          if (mode != PoiFilterMode.none) {
            _resetCarousel();
          }
        }
        if (mode == PoiFilterMode.none && _pageIndex != 0) {
          _resetCarousel();
        }
        if (mode != PoiFilterMode.none) {
          return StreamValueBuilder<List<CityPoiModel>>(
            streamValue: _controller.filteredPoisStreamValue,
            builder: (_, filtered) {
              if (filtered.isEmpty) {
                return const SizedBox.shrink();
              }
              final clampedIndex =
                  _pageIndex.clamp(0, filtered.length - 1).toInt();
              if (clampedIndex != _pageIndex &&
                  _pageController.hasClients &&
                  mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!_pageController.hasClients) return;
                  _pageController.jumpToPage(0);
                });
                _pageIndex = clampedIndex;
              }
              final currentPoi = filtered[_pageIndex];
              final deckHeight = _heightForPoi(context, currentPoi);
              return _FilteredDeck(
                pois: filtered,
                controller: _controller,
                colorScheme: scheme,
                pageController: _pageController,
                cardBuilder: _cardBuilder,
                onPrimaryAction: _handlePoiAction,
                onShare: _handleShare,
                onRoute: _handleRoute,
                onChanged: (index) {
                  setState(() => _pageIndex = index);
                  final poi = filtered[index];
                  _controller.selectPoi(poi);
                  unawaited(_controller.focusOnPoi(poi));
                },
                deckHeight: deckHeight,
                onCardHeightChanged: (poiId, height) =>
                    _handleMeasuredHeight(context, poiId, height),
              );
            },
          );
        }

        return StreamValueBuilder<CityPoiModel?>(
          streamValue: _controller.selectedPoiStreamValue,
          onNullWidget: const SizedBox.shrink(),
          builder: (_, poi) {
            final deckHeight = _heightForPoi(context, poi!);
            return _SinglePoiCard(
              poi: poi,
              colorScheme: scheme,
              cardBuilder: _cardBuilder,
              onPrimaryAction: _handlePoiAction,
              onShare: _handleShare,
              onRoute: _handleRoute,
              onCardHeightChanged: (poiId, height) =>
                  _handleMeasuredHeight(context, poiId, height),
              deckHeight: deckHeight,
            );
          },
        );
      },
    );
  }

  void _resetCarousel() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (_pageIndex != 0) {
        setState(() => _pageIndex = 0);
      }
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    });
  }

  void _handlePoiAction(CityPoiModel poi) {
    if (poi is EventPoiModel) {
      final slug = poi.event.slug;
      if (slug.isNotEmpty && mounted) {
        context.router.push(ImmersiveEventDetailRoute(eventSlug: slug));
      }
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Abrindo ${poi.name}')),
      );
  }

  Future<void> _handleShare(CityPoiModel poi) async {
    final payload = _buildSharePayload(poi);
    try {
      await SharePlus.instance.share(
        ShareParams(text: payload.message, subject: payload.subject),
      );
    } catch (_) {
      _showMessage('Não foi possível compartilhar ${poi.name}.');
    }
  }

  Future<void> _handleRoute(CityPoiModel poi) async {
    final info = await _prepareDirections(poi);
    if (info == null) {
      _showMessage('Localização indisponível para ${poi.name}.');
      return;
    }
    if (!mounted) return;
    await _presentDirectionsOptions(info);
  }


  Future<DirectionsInfo?> _prepareDirections(CityPoiModel poi) async {
    final coordinate = poi.coordinate;
    return _buildDirectionsInfo(coordinate, poi.name);
  }

  Future<DirectionsInfo?> _buildDirectionsInfo(
    CityCoordinate coordinate,
    String destinationName,
  ) async {
    final destination = Coords(
      coordinate.latitude,
      coordinate.longitude,
    );

    try {
      final availableMaps = await MapLauncher.installedMaps;
      final rideShareOptions =
          await _availableRideShareOptions(destination, destinationName);
      final fallbackUrl =
          _buildFallbackDirectionsUri(destination, destinationName);
      return DirectionsInfo(
        coordinate: coordinate,
        destination: destination,
        destinationName: destinationName,
        availableMaps: availableMaps,
        rideShareOptions: rideShareOptions,
        fallbackUrl: fallbackUrl,
      );
    } catch (_) {
      final fallbackUrl =
          _buildFallbackDirectionsUri(destination, destinationName);
      return DirectionsInfo(
        coordinate: coordinate,
        destination: destination,
        destinationName: destinationName,
        availableMaps: const [],
        rideShareOptions: const [],
        fallbackUrl: fallbackUrl,
      );
    }
  }

  Uri _buildFallbackDirectionsUri(Coords destination, String destinationName) {
    return Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${destination.latitude},${destination.longitude}'
      '&destination_place_id=${Uri.encodeComponent(destinationName)}',
    );
  }

  Future<List<RideShareOption>> _availableRideShareOptions(
    Coords destination,
    String destinationName,
  ) async {
    final options = <RideShareOption>[];
    final latitude = destination.latitude;
    final longitude = destination.longitude;
    final encodedTitle = Uri.encodeComponent(destinationName);

    final uberUris = <Uri>[
      Uri.parse(
        'uber://?action=setPickup'
        '&dropoff[latitude]=$latitude'
        '&dropoff[longitude]=$longitude'
        '&dropoff[nickname]=$encodedTitle',
      ),
      Uri.parse(
        'https://m.uber.com/ul/?action=setPickup'
        '&dropoff[latitude]=$latitude'
        '&dropoff[longitude]=$longitude'
        '&dropoff[nickname]=$encodedTitle',
      ),
    ];
    if (await _hasAnyLaunchHandler(uberUris)) {
      options.add(
        RideShareOption(
          provider: RideShareProvider.uber,
          label: 'Uber',
          uris: uberUris,
        ),
      );
    }

    final ninetyNineUris = <Uri>[
      Uri.parse(
        'ninetynine://ride?dropoff_latitude=$latitude'
        '&dropoff_longitude=$longitude'
        '&dropoff_title=$encodedTitle',
      ),
      Uri.parse(
        'https://app.99app.com/open?deep_link_value=ride'
        '&dropoff_latitude=$latitude'
        '&dropoff_longitude=$longitude'
        '&dropoff_title=$encodedTitle',
      ),
    ];
    if (await _hasAnyLaunchHandler(ninetyNineUris)) {
      options.add(
        RideShareOption(
          provider: RideShareProvider.ninetyNine,
          label: '99',
          uris: ninetyNineUris,
        ),
      );
    }

    return options;
  }

  Future<void> _presentDirectionsOptions(DirectionsInfo info) async {
    final maps = info.availableMaps;
    final rideShares = info.rideShareOptions;
    final totalOptions = maps.length + rideShares.length;

    if (totalOptions == 0) {
      await _launchFallbackDirections(info);
      return;
    }

    if (totalOptions == 1) {
      if (maps.length == 1) {
        await maps.first.showDirections(
          destination: info.destination,
          destinationTitle: info.destinationName,
        );
      } else {
        final success = await _launchRideShareOption(rideShares.first);
        if (!success) {
          await _launchFallbackDirections(info);
        }
      }
      return;
    }

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Escolha como chegar',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
              for (final map in maps)
                ListTile(
                  leading: SvgPicture.asset(
                    map.icon,
                    width: 32,
                    height: 32,
                  ),
                  title: Text(map.mapName),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await map.showDirections(
                      destination: info.destination,
                      destinationTitle: info.destinationName,
                    );
                  },
                ),
              if (maps.isNotEmpty && rideShares.isNotEmpty)
                const Divider(height: 1),
              for (final option in rideShares)
                ListTile(
                  leading: Icon(
                    _rideShareIcon(option.provider),
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(option.label),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final success = await _launchRideShareOption(option);
                    if (!success) {
                      await _launchFallbackDirections(info);
                    }
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchFallbackDirections(DirectionsInfo info) async {
    final launched = await launchUrl(
      info.fallbackUrl,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      _showMessage(
          'Não foi possível abrir rotas para ${info.destinationName}.');
    }
  }

  Future<bool> _launchRideShareOption(RideShareOption option) {
    return _launchFirstSupportedUri(option.uris, option.label);
  }

  Future<bool> _launchFirstSupportedUri(
    List<Uri> uris,
    String providerName,
  ) async {
    for (final uri in uris) {
      if (await _safeCanLaunch(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) {
          return true;
        }
      }
    }
    debugPrint('No handler available for $providerName');
    return false;
  }

  Future<bool> _hasAnyLaunchHandler(List<Uri> uris) async {
    for (final uri in uris) {
      if (await _safeCanLaunch(uri)) {
        return true;
      }
    }
    return false;
  }

  Future<bool> _safeCanLaunch(Uri uri) async {
    try {
      return await canLaunchUrl(uri);
    } catch (_) {
      return false;
    }
  }

  IconData _rideShareIcon(RideShareProvider provider) {
    switch (provider) {
      case RideShareProvider.uber:
        return Icons.local_taxi;
      case RideShareProvider.ninetyNine:
        return Icons.local_taxi_outlined;
    }
  }

  _SharePayload _buildSharePayload(CityPoiModel poi) {
    if (poi is EventPoiModel) {
      final event = poi.event;
      final lines = <String>[
        event.title.value,
        if (event.location.value.isNotEmpty) event.location.value,
      ];
      final start = event.dateTimeStart.value;
      if (start != null) {
        lines.add('Início: ${DateFormat('dd/MM/yyyy HH:mm').format(start)}');
      }
      final coordinate = event.coordinate;
      if (coordinate != null) {
        lines.add(
          'Mapa: https://maps.google.com/?q='
          '${coordinate.latitude},${coordinate.longitude}',
        );
      }
      final message = lines.where((line) => line.trim().isNotEmpty).join('\n');
      return _SharePayload(subject: event.title.value, message: message);
    }

    final details = <String>[
      poi.name,
      if (poi.description.isNotEmpty) poi.description,
      poi.address,
    ];
    final message = details.where((line) => line.trim().isNotEmpty).join('\n');
    return _SharePayload(subject: poi.name, message: message);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleMeasuredHeight(
    BuildContext context,
    String poiId,
    double height,
  ) {
    if (height.isNaN || height <= 0) {
      return;
    }
    final clamped = _clampHeight(context, height);
    final previous = _poiHeights[poiId];
    if (previous != null && (previous - clamped).abs() < 1) {
      return;
    }
    setState(() {
      _poiHeights[poiId] = clamped;
    });
  }

  double _heightForPoi(BuildContext context, CityPoiModel poi) {
    final raw = _poiHeights[poi.id] ?? _defaultCardHeight;
    return _clampHeight(context, raw);
  }

  double _clampHeight(BuildContext context, double raw) {
    final maxHeight = MediaQuery.of(context).size.height * 0.55;
    return raw.clamp(_minCardHeight, maxHeight);
  }
}

class _SizeReportingWidget extends SingleChildRenderObjectWidget {
  const _SizeReportingWidget({
    required this.onSizeChanged,
    required super.child,
  });

  final ValueChanged<Size> onSizeChanged;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSizeReporting(onSizeChanged);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderSizeReporting renderObject,
  ) {
    renderObject.onSizeChanged = onSizeChanged;
  }
}

class _RenderSizeReporting extends RenderProxyBox {
  _RenderSizeReporting(this.onSizeChanged);

  ValueChanged<Size> onSizeChanged;
  Size? _oldSize;

  @override
  void performLayout() {
    super.performLayout();
    if (size != _oldSize) {
      _oldSize = size;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (attached) {
          onSizeChanged(size);
        }
      });
    }
  }
}

class _SharePayload {
  const _SharePayload({required this.subject, required this.message});

  final String subject;
  final String message;
}

class _FilteredDeck extends StatelessWidget {
  const _FilteredDeck({
    required this.pois,
    required this.controller,
    required this.colorScheme,
    required this.pageController,
    required this.cardBuilder,
    required this.onPrimaryAction,
    required this.onShare,
    required this.onRoute,
    required this.onChanged,
    required this.deckHeight,
    required this.onCardHeightChanged,
  });

  final List<CityPoiModel> pois;
  final MapScreenController controller;
  final ColorScheme colorScheme;
  final PageController pageController;
  final PoiDetailCardBuilder cardBuilder;
  final ValueChanged<CityPoiModel> onPrimaryAction;
  final ValueChanged<CityPoiModel> onShare;
  final ValueChanged<CityPoiModel> onRoute;
  final ValueChanged<int> onChanged;
  final double deckHeight;
  final void Function(String poiId, double height) onCardHeightChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _iconForFilterMode(controller.filterModeStreamValue.value),
              color: _accentColorForFilter(
                controller.filterModeStreamValue.value,
                colorScheme,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _titleForFilterMode(controller.filterModeStreamValue.value),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          height: deckHeight,
          child: PageView.builder(
            controller: pageController,
            padEnds: false,
            itemCount: pois.length,
            onPageChanged: onChanged,
            itemBuilder: (context, index) {
              final poi = pois[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index == pois.length - 1 ? 0 : 12,
                ),
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  minHeight: 0,
                  maxHeight: double.infinity,
                  child: _SizeReportingWidget(
                    onSizeChanged: (size) => onCardHeightChanged(
                      poi.id,
                      size.height + _kDeckMeasurementPadding,
                    ),
                    child: cardBuilder.build(
                      context: context,
                      poi: poi,
                      colorScheme: colorScheme,
                      onPrimaryAction: () {
                        controller.selectPoi(poi);
                        onPrimaryAction(poi);
                      },
                      onShare: () => onShare(poi),
                      onRoute: () => onRoute(poi),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  String _titleForFilterMode(PoiFilterMode mode) {
    switch (mode) {
      case PoiFilterMode.events:
        return 'Eventos em destaque';
      case PoiFilterMode.restaurants:
        return 'Sugestões gastronômicas';
      case PoiFilterMode.beaches:
        return 'Praias recomendadas';
      case PoiFilterMode.lodging:
        return 'Hospedagens parceiras';
      case PoiFilterMode.none:
        return 'Pontos selecionados';
    }
  }

  IconData _iconForFilterMode(PoiFilterMode mode) {
    switch (mode) {
      case PoiFilterMode.events:
        return Icons.local_activity;
      case PoiFilterMode.restaurants:
        return Icons.restaurant;
      case PoiFilterMode.beaches:
        return Icons.beach_access;
      case PoiFilterMode.lodging:
        return Icons.hotel;
      case PoiFilterMode.none:
        return Icons.map;
    }
  }

  Color _accentColorForFilter(
    PoiFilterMode mode,
    ColorScheme scheme,
  ) {
    switch (mode) {
      case PoiFilterMode.events:
        return scheme.primary;
      case PoiFilterMode.restaurants:
        return categoryTheme(CityPoiCategory.restaurant, scheme).color;
      case PoiFilterMode.beaches:
        return categoryTheme(CityPoiCategory.beach, scheme).color;
      case PoiFilterMode.lodging:
        return categoryTheme(CityPoiCategory.lodging, scheme).color;
      case PoiFilterMode.none:
        return scheme.primary;
    }
  }
}

class _SinglePoiCard extends StatelessWidget {
  const _SinglePoiCard({
    required this.poi,
    required this.colorScheme,
    required this.cardBuilder,
    required this.onPrimaryAction,
    required this.onShare,
    required this.onRoute,
    required this.onCardHeightChanged,
    required this.deckHeight,
  });

  final CityPoiModel poi;
  final ColorScheme colorScheme;
  final PoiDetailCardBuilder cardBuilder;
  final ValueChanged<CityPoiModel> onPrimaryAction;
  final ValueChanged<CityPoiModel> onShare;
  final ValueChanged<CityPoiModel> onRoute;
  final void Function(String poiId, double height) onCardHeightChanged;
  final double deckHeight;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      height: deckHeight,
      child: OverflowBox(
        alignment: Alignment.topCenter,
        minHeight: 0,
        maxHeight: double.infinity,
        child: _SizeReportingWidget(
          onSizeChanged: (size) => onCardHeightChanged(
              poi.id, size.height + _kDeckMeasurementPadding),
          child: cardBuilder.build(
            context: context,
            poi: poi,
            colorScheme: colorScheme,
            onPrimaryAction: () => onPrimaryAction(poi),
            onShare: () => onShare(poi),
            onRoute: () => onRoute(poi),
          ),
        ),
      ),
    );
  }
}
