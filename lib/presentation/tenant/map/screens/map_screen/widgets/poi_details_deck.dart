import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/direction_info.dart';
import 'package:belluga_now/domain/map/event_poi_model.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_mode.dart';
import 'package:belluga_now/domain/map/ride_share_option.dart';
import 'package:belluga_now/domain/map/ride_share_provider.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/presentation/tenant/map/screens/map_screen/controllers/map_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/map_screen/widgets/filtered_deck.dart';
import 'package:belluga_now/presentation/tenant/map/screens/map_screen/widgets/poi_detail_card_builder.dart';
import 'package:belluga_now/presentation/tenant/map/screens/map_screen/widgets/single_poi_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:url_launcher/url_launcher.dart';

const double _kDeckMeasurementPadding = 32;

class PoiDetailDeck extends StatefulWidget {
  const PoiDetailDeck({
    super.key,
    required this.controller,
  });

  final MapScreenController controller;

  @override
  State<PoiDetailDeck> createState() => _PoiDetailDeckState();
}

class _PoiDetailDeckState extends State<PoiDetailDeck>
    with TickerProviderStateMixin {
  late final MapScreenController _controller = widget.controller;
  final PageController _pageController = PageController(viewportFraction: 0.8);
  final PoiDetailCardBuilder _cardBuilder = const PoiDetailCardBuilder();
  PoiFilterMode? _lastFilterMode;
  int? _lastPoiDeckIndex;

  static const double _defaultCardHeight = 320;
  static const double _minCardHeight = 220;

  @override
  void initState() {
    super.initState();
    _lastFilterMode = _controller.filterModeStreamValue.value;
    _lastPoiDeckIndex = _controller.poiDeckIndexStreamValue.value;
    _applyFilterMode(_lastFilterMode!);
    _applyPoiDeckIndex(_lastPoiDeckIndex!);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _applyFilterMode(PoiFilterMode mode) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.lastPoiDeckFilterMode != mode) {
        _controller.lastPoiDeckFilterMode = mode;
        if (mode != PoiFilterMode.none) {
          _resetCarousel();
        }
      }
      if (mode == PoiFilterMode.none &&
          _controller.poiDeckIndexStreamValue.value != 0) {
        _resetCarousel();
      }
    });
  }

  void _applyPoiDeckIndex(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_pageController.hasClients) {
        return;
      }
      final pageIndex = _pageController.page?.round();
      if (pageIndex != null && pageIndex != index) {
        _pageController.jumpToPage(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return StreamValueBuilder<PoiFilterMode>(
      streamValue: _controller.filterModeStreamValue,
      builder: (_, mode) {
        if (_lastFilterMode != mode) {
          _lastFilterMode = mode;
          _applyFilterMode(mode);
        }
        if (mode != PoiFilterMode.none) {
          return StreamValueBuilder<List<CityPoiModel>>(
            streamValue: _controller.filteredPoisStreamValue,
            builder: (_, filtered) {
              if (filtered.isEmpty) {
                return const SizedBox.shrink();
              }
              return StreamValueBuilder<int>(
                streamValue: _controller.poiDeckIndexStreamValue,
                builder: (_, pageIndex) {
                  if (_lastPoiDeckIndex != pageIndex) {
                    _lastPoiDeckIndex = pageIndex;
                    _applyPoiDeckIndex(pageIndex);
                  }
                  final clampedIndex =
                      pageIndex.clamp(0, filtered.length - 1).toInt();
                  final currentPoi = filtered[clampedIndex];
                  final deckHeight = _heightForPoi(context, currentPoi);
                  return FilteredDeck(
                    pois: filtered,
                    controller: _controller,
                    colorScheme: scheme,
                    pageController: _pageController,
                    cardBuilder: _cardBuilder,
                    onPrimaryAction: _handlePoiAction,
                    onShare: _handleShare,
                    onRoute: _handleRoute,
                    onChanged: (index) {
                      _controller.setPoiDeckIndex(index);
                      final poi = filtered[index];
                      _controller.selectPoi(poi);
                      unawaited(_controller.focusOnPoi(poi));
                    },
                    deckHeight: deckHeight,
                    onCardHeightChanged: (poiId, height) =>
                        _handleMeasuredHeight(context, poiId, height),
                    deckMeasurementPadding: _kDeckMeasurementPadding,
                  );
                },
              );
            },
          );
        }

        return StreamValueBuilder<CityPoiModel?>(
          streamValue: _controller.selectedPoiStreamValue,
          onNullWidget: const SizedBox.shrink(),
          builder: (_, poi) {
            final deckHeight = _heightForPoi(context, poi!);
            return SinglePoiCard(
              poi: poi,
              colorScheme: scheme,
              cardBuilder: _cardBuilder,
              onPrimaryAction: _handlePoiAction,
              onShare: _handleShare,
              onRoute: _handleRoute,
              onCardHeightChanged: (poiId, height) =>
                  _handleMeasuredHeight(context, poiId, height),
              deckHeight: deckHeight,
              deckMeasurementPadding: _kDeckMeasurementPadding,
            );
          },
        );
      },
    );
  }

  void _resetCarousel() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.resetPoiDeckIndex();
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    });
  }

  void _handlePoiAction(CityPoiModel poi) {
    if (poi is EventPoiModel) {
      final slug = poi.event.slug;
      if (slug.isNotEmpty) {
        context.router.push(ImmersiveEventDetailRoute(eventSlug: slug));
      }
      return;
    }
    _controller.statusMessageStreamValue.addValue('Abrindo ${poi.name}');
  }

  Future<void> _handleShare(CityPoiModel poi) async {
    final payload = _buildSharePayload(poi);
    try {
      await SharePlus.instance.share(
        ShareParams(text: payload.message, subject: payload.subject),
      );
    } catch (_) {
      _controller.statusMessageStreamValue
          .addValue('Não foi possível compartilhar ${poi.name}.');
    }
  }

  Future<void> _handleRoute(CityPoiModel poi) async {
    _controller.logDirectionsOpened(poi);
    final info = await _prepareDirections(poi);
    if (info == null) {
      _controller.statusMessageStreamValue
          .addValue('Localização indisponível para ${poi.name}.');
      return;
    }
    await _presentDirectionsOptions(info, poi);
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

  Future<void> _presentDirectionsOptions(
    DirectionsInfo info,
    CityPoiModel poi,
  ) async {
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
        final success = await _launchRideShareOption(rideShares.first, poi);
        if (!success) {
          await _launchFallbackDirections(info);
        }
      }
      return;
    }

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
                    sheetContext.router.pop();
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
                    sheetContext.router.pop();
                    final success = await _launchRideShareOption(option, poi);
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
      _controller.statusMessageStreamValue.addValue(
        'Não foi possível abrir rotas para ${info.destinationName}.',
      );
    }
  }

  Future<bool> _launchRideShareOption(
    RideShareOption option,
    CityPoiModel poi,
  ) {
    _controller.logRideShareClicked(
      provider: option.provider,
      poiId: poi.id,
    );
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

  void _handleMeasuredHeight(
    BuildContext context,
    String poiId,
    double height,
  ) {
    if (height.isNaN || height <= 0) {
      return;
    }
    final clamped = _clampHeight(context, height);
    final previous = _controller.getPoiDeckHeight(poiId);
    if (previous != null && (previous - clamped).abs() < 1) {
      return;
    }
    _controller.updatePoiDeckHeight(poiId, clamped);
  }

  double _heightForPoi(BuildContext context, CityPoiModel poi) {
    final raw = _controller.getPoiDeckHeight(poi.id) ?? _defaultCardHeight;
    return _clampHeight(context, raw);
  }

  double _clampHeight(BuildContext context, double raw) {
    final maxHeight = MediaQuery.of(context).size.height * 0.55;
    return raw.clamp(_minCardHeight, maxHeight);
  }
}

class _SharePayload {
  const _SharePayload({required this.subject, required this.message});

  final String subject;
  final String message;
}
