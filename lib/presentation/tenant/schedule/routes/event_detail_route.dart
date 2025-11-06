import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/schedule_module.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_detail_screen/controllers/event_detail_controller.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_detail_screen/event_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'EventDetailRoute')
class EventDetailRoutePage extends StatelessWidget {
  const EventDetailRoutePage({
    super.key,
    @PathParam('slug') required this.slug,
  });

  final String slug;

  @override
  Widget build(BuildContext context) {
    return ModuleScope<ScheduleModule>(
      child: _EventDetailLoader(slug: slug),
    );
  }
}

class _EventDetailLoader extends StatefulWidget {
  const _EventDetailLoader({required this.slug});

  final String slug;

  @override
  State<_EventDetailLoader> createState() => _EventDetailLoaderState();
}

class _EventDetailLoaderState extends State<_EventDetailLoader> {
  late final EventDetailController _controller =
      GetIt.I.get<EventDetailController>();
  late final Future<EventModel?> _eventFuture;

  @override
  void initState() {
    super.initState();
    _eventFuture = _controller.loadEvent(widget.slug);
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
