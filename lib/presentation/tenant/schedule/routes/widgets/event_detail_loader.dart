import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_detail_screen/controllers/event_detail_controller.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_detail_screen/event_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class EventDetailLoader extends StatefulWidget {
  const EventDetailLoader({
    super.key,
    required this.slug,
    this.controller,
  });

  final String slug;
  final EventDetailController? controller;

  @override
  State<EventDetailLoader> createState() => _EventDetailLoaderState();
}

class _EventDetailLoaderState extends State<EventDetailLoader> {
  late final EventDetailController _controller =
      widget.controller ?? GetIt.I.get<EventDetailController>();
  late final Future<EventModel?> _eventFuture;

  @override
  void initState() {
    super.initState();
    _eventFuture = _controller.loadEventBySlug(widget.slug).then((_) {
      return _controller.eventStreamValue.value;
    });
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

        return EventDetailScreen(event: event);
      },
    );
  }
}
