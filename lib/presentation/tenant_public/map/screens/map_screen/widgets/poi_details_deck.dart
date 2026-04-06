import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/projections/city_poi_stack_items.dart';
import 'package:belluga_now/domain/map/value_objects/poi_stack_count_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_stack_key_value.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/filtered_deck.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/poi_detail_card_builder.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/single_poi_card.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_chooser.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_chooser_contract.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_launch_target.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stream_value/core/stream_value_builder.dart';

const double _kDeckMeasurementPadding = 32;

class PoiDetailDeck extends StatefulWidget {
  const PoiDetailDeck({
    super.key,
    required this.controller,
    this.directionsAppChooser,
  });

  final MapScreenController controller;
  final DirectionsAppChooserContract? directionsAppChooser;

  @override
  State<PoiDetailDeck> createState() => _PoiDetailDeckState();
}

class _PoiDetailDeckState extends State<PoiDetailDeck>
    with TickerProviderStateMixin {
  late final MapScreenController _controller = widget.controller;
  late final DirectionsAppChooserContract _directionsAppChooser =
      widget.directionsAppChooser ?? DirectionsAppChooser();
  final PageController _pageController = PageController(viewportFraction: 0.9);
  final PoiDetailCardBuilder _cardBuilder = const PoiDetailCardBuilder();
  int? _lastPoiDeckIndex;

  static const double _defaultCardHeight = 356;
  static const double _minCardHeight = 280;

  @override
  void initState() {
    super.initState();
    _lastPoiDeckIndex = _controller.poiDeckIndexStreamValue.value;
    _applyPoiDeckIndex(_lastPoiDeckIndex!);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
    return StreamValueBuilder<CityPoiModel?>(
      streamValue: _controller.selectedPoiStreamValue,
      onNullWidget: const SizedBox.shrink(),
      builder: (_, poi) {
        final selectedPoi = poi!;
        final child = _buildSelectedDeck(
          context: context,
          scheme: scheme,
          selectedPoi: selectedPoi,
        );
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topRight,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, right: 2),
              child: child,
            ),
            Material(
              color: scheme.surface.withValues(alpha: 0.98),
              shape: const CircleBorder(),
              elevation: 10,
              child: IconButton(
                tooltip: 'Fechar',
                onPressed: _controller.clearSelectedPoi,
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSelectedDeck({
    required BuildContext context,
    required ColorScheme scheme,
    required CityPoiModel selectedPoi,
  }) {
    final stackPois = _stackDeckItems(selectedPoi);
    if (stackPois.length > 1) {
      return StreamValueBuilder<int>(
        streamValue: _controller.poiDeckIndexStreamValue,
        builder: (_, pageIndex) {
          final selectedIndex = stackPois.indexWhere(
            (candidate) => candidate.id == selectedPoi.id,
          );
          final desiredIndex = selectedIndex == -1 ? pageIndex : selectedIndex;
          final clampedIndex =
              desiredIndex.clamp(0, stackPois.length - 1).toInt();
          if (clampedIndex != pageIndex) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _controller.setPoiDeckIndex(clampedIndex);
            });
          }
          if (_lastPoiDeckIndex != clampedIndex) {
            _lastPoiDeckIndex = clampedIndex;
            _applyPoiDeckIndex(clampedIndex);
          }
          final currentPoi = stackPois[clampedIndex];
          final deckHeight = _heightForPoi(context, currentPoi);
          return FilteredDeck(
            pois: stackPois,
            controller: _controller,
            colorScheme: scheme,
            pageController: _pageController,
            cardBuilder: _cardBuilder,
            onPrimaryAction: _handlePoiAction,
            onShare: _handleShare,
            onRoute: _handleRoute,
            onChanged: (index) {
              _controller.setPoiDeckIndex(index);
              final poi = stackPois[index];
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
    }

    final deckHeight = _heightForPoi(context, selectedPoi);
    return SinglePoiCard(
      poi: selectedPoi,
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
  }

  void _handlePoiAction(CityPoiModel poi) {
    if (_isEventPoi(poi)) {
      final eventSlug = _resolveEventSlug(poi);
      if (eventSlug.isNotEmpty) {
        context.router.push(ImmersiveEventDetailRoute(eventSlug: eventSlug));
        return;
      }
      _controller.statusMessageStreamValue.addValue(
        'Evento sem referência para abrir detalhes.',
      );
      return;
    }
    final poiQueryKey = _controller.buildPoiQueryKey(poi);
    if (poiQueryKey.isEmpty) {
      _controller.statusMessageStreamValue.addValue(
        'POI sem referência para abrir detalhes.',
      );
      return;
    }
    final stackQueryKey = poi.stackKey.trim();
    context.router.replace(
      CityMapRoute(
        poi: poiQueryKey,
        stack: stackQueryKey.isEmpty ? null : stackQueryKey,
      ),
    );
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
    final target = _directionsTargetFromPoi(poi);
    if (target == null) {
      _controller.statusMessageStreamValue
          .addValue('Localização indisponível para ${poi.name}.');
      return;
    }
    await _directionsAppChooser.present(
      context,
      target: target,
      onStatusMessage: _controller.statusMessageStreamValue.addValue,
    );
  }

  DirectionsLaunchTarget? _directionsTargetFromPoi(CityPoiModel poi) {
    final address = poi.address.trim();
    return DirectionsLaunchTarget(
      destinationName: poi.name,
      latitude: poi.coordinate.latitude,
      longitude: poi.coordinate.longitude,
      address: address.isEmpty ? null : address,
    );
  }

  bool _isEventPoi(CityPoiModel poi) {
    if (poi.refType.trim().toLowerCase() == 'event') {
      return true;
    }
    return poi.isDynamic;
  }

  String _resolveEventSlug(CityPoiModel poi) {
    final slug = poi.refSlug?.trim() ?? '';
    if (slug.isNotEmpty) {
      return slug;
    }
    final fromPath = _extractSlugFromPath(poi.refPath);
    if (fromPath.isNotEmpty) {
      return fromPath;
    }
    return poi.refId.trim();
  }

  String _extractSlugFromPath(String? refPath) {
    final path = refPath?.trim() ?? '';
    if (path.isEmpty) {
      return '';
    }
    try {
      final segments = Uri.parse(path)
          .pathSegments
          .where((segment) => segment.trim().isNotEmpty)
          .toList(growable: false);
      if (segments.isEmpty) {
        return '';
      }
      return segments.last.trim();
    } catch (_) {
      return '';
    }
  }

  List<CityPoiModel> _stackDeckItems(CityPoiModel selectedPoi) {
    if (selectedPoi.stackItems.isEmpty) {
      return const <CityPoiModel>[];
    }

    final fallbackStackKey = selectedPoi.stackItems.first.stackKey.trim();
    final normalizedStackKey = selectedPoi.stackKey.trim().isNotEmpty
        ? selectedPoi.stackKey.trim()
        : fallbackStackKey;
    final normalizedStackCount = selectedPoi.stackCount > 0
        ? selectedPoi.stackCount
        : selectedPoi.stackItems.length;

    final uniqueById = <String, CityPoiModel>{};
    for (final item in selectedPoi.stackItems) {
      uniqueById[item.id] = item;
    }
    uniqueById[selectedPoi.id] = selectedPoi;

    final ordered = uniqueById.values.toList(growable: false)
      ..sort((a, b) {
        final byPriority = b.priority.compareTo(a.priority);
        if (byPriority != 0) {
          return byPriority;
        }
        return a.id.compareTo(b.id);
      });

    final seeded = ordered
        .map(
          (item) => item.copyWith(
            stackKeyValue: _parseStackKeyValue(normalizedStackKey),
            stackCountValue: _parseStackCountValue(normalizedStackCount),
          ),
        )
        .toList(growable: false);
    final stackItems = CityPoiStackItems();
    for (final item in seeded) {
      stackItems.add(item);
    }
    return seeded
        .map(
          (item) => item.copyWith(stackItems: stackItems),
        )
        .toList(growable: false);
  }

  PoiStackKeyValue _parseStackKeyValue(String raw) {
    final value = PoiStackKeyValue();
    value.parse(raw.trim());
    return value;
  }

  PoiStackCountValue _parseStackCountValue(int raw) {
    final value = PoiStackCountValue();
    value.parse(raw.toString());
    return value;
  }

  _SharePayload _buildSharePayload(CityPoiModel poi) {
    if (_isEventPoi(poi)) {
      final lines = <String>[
        poi.name,
        if (poi.address.isNotEmpty) poi.address,
        if (poi.description.isNotEmpty) poi.description,
      ];
      if (poi.updatedAt != null) {
        lines.add(
          'Atualizado em ${DateFormat('dd/MM/yyyy HH:mm').format(poi.updatedAt!)}',
        );
      }
      final eventPath = poi.refPath?.trim() ?? '';
      if (eventPath.isNotEmpty) {
        lines.add('Detalhes: $eventPath');
      }
      lines.add(
        'Mapa: https://maps.google.com/?q='
        '${poi.coordinate.latitude},${poi.coordinate.longitude}',
      );
      final message = lines.where((line) => line.trim().isNotEmpty).join('\n');
      return _SharePayload(subject: poi.name, message: message);
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
    final viewportHeight = MediaQuery.of(context).size.height;
    final maxHeight = (viewportHeight * 0.56).clamp(340.0, 480.0);
    return raw.clamp(_minCardHeight, maxHeight);
  }
}

class _SharePayload {
  const _SharePayload({required this.subject, required this.message});

  final String subject;
  final String message;
}
