import 'dart:async';

import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/common/widgets/image_palette_theme.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_detail_screen/controllers/event_detail_controller.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_detail_screen/event_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class EventDetailLoader extends StatefulWidget {
  const EventDetailLoader({
    super.key,
    required this.slug,
  });

  final String slug;

  @override
  State<EventDetailLoader> createState() => _EventDetailLoaderState();
}

class _EventDetailLoaderState extends State<EventDetailLoader> {
  final EventDetailController _controller =
      GetIt.I.get<EventDetailController>();
  StreamSubscription<EventModel?>? _eventSubscription;
  bool _telemetryStarted = false;

  @override
  void initState() {
    super.initState();
    _eventSubscription = _controller.eventStreamValue.stream.listen((event) {
      if (event == null || _telemetryStarted) return;
      _telemetryStarted = true;
      unawaited(_controller.startEventTelemetry(event));
    });
    unawaited(_controller.loadEventBySlug(widget.slug));
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    unawaited(_controller.finishEventTelemetry());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<EventModel?>(
      streamValue: _controller.eventStreamValue,
      builder: (context, _) {
        if (_controller.isLoadingStreamValue.value &&
            _controller.eventStreamValue.value == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final event = _controller.eventStreamValue.value;
        if (event == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Evento')),
            body: const Center(
              child: Text('Evento não encontrado.'),
            ),
          );
        }

        final thumb = event.thumb?.thumbUri.value;
        if (thumb == null) {
          return EventDetailScreen(
            event: event,
          );
        }

        return ImagePaletteTheme(
          imageProvider: NetworkImage(thumb.toString()),
          builder: (context, scheme) {
            return EventDetailScreen(
              event: event,
              colorScheme: scheme,
            );
          },
        );
      },
    );
  }
}
