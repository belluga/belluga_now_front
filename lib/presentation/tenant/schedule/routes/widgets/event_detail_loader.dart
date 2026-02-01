import 'dart:async';

import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/common/widgets/image_palette_theme.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_detail_screen/controllers/event_detail_controller.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_detail_screen/event_detail_screen.dart';
import 'package:flutter/material.dart';

class EventDetailLoader extends StatefulWidget {
  const EventDetailLoader({
    super.key,
    required this.slug,
    required this.controller,
  });

  final String slug;
  final EventDetailController controller;

  @override
  State<EventDetailLoader> createState() => _EventDetailLoaderState();
}

class _EventDetailLoaderState extends State<EventDetailLoader> {
  EventDetailController get _controller => widget.controller;
  late Future<EventModel?> _eventFuture;

  @override
  void initState() {
    super.initState();
    _eventFuture = _controller.loadEventBySlug(widget.slug).then((_) async {
      final event = _controller.eventStreamValue.value;
      if (event != null && mounted) {
        await _controller.startEventTelemetry(event);
      }
      return event;
    });
  }

  @override
  void dispose() {
    unawaited(_controller.finishEventTelemetry());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<EventModel?>(
      future: _eventFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final event = snapshot.data;
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
            controller: _controller,
          );
        }

        return ImagePaletteTheme(
          imageProvider: NetworkImage(thumb.toString()),
          builder: (context, scheme) {
            return EventDetailScreen(
              event: event,
              controller: _controller,
              colorScheme: scheme,
            );
          },
        );
      },
    );
  }
}
