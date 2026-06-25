import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/presentation/tenant_admin/events/controllers/tenant_admin_events_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/events/screens/tenant_admin_event_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

@RoutePage(name: 'TenantAdminEventEditRoute')
class TenantAdminEventEditRoutePage extends StatefulWidget {
  const TenantAdminEventEditRoutePage({
    this.event,
    super.key,
  });

  final TenantAdminEvent? event;

  @override
  State<TenantAdminEventEditRoutePage> createState() =>
      _TenantAdminEventEditRoutePageState();
}

class _TenantAdminEventEditRoutePageState
    extends State<TenantAdminEventEditRoutePage> {
  TenantAdminEventsController? _controller;

  TenantAdminEventsController get _resolvedController =>
      _controller ??= GetIt.I.get<TenantAdminEventsController>();

  @override
  void initState() {
    super.initState();
    _syncSelectedEventDetail();
  }

  @override
  void didUpdateWidget(covariant TenantAdminEventEditRoutePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previousEventId = oldWidget.event?.eventId;
    final nextEventId = widget.event?.eventId;
    if (previousEventId == nextEventId) {
      return;
    }

    _controller?.resetEventDetailState();
    _syncSelectedEventDetail();
  }

  @override
  void dispose() {
    _controller?.resetEventDetailState();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvent = widget.event;
    if (selectedEvent == null) {
      return _UnavailableScaffold(
        onBack: () => context.router.replace(const TenantAdminEventsRoute()),
      );
    }

    final controller = _resolvedController;
    final selectedOccurrenceId = selectedEvent.occurrences.firstOrNull?.occurrenceId;

    return StreamValueBuilder<bool>(
      streamValue: controller.eventDetailLoadingStreamValue,
      builder: (context, isLoading) {
        return StreamValueBuilder<String?>(
          streamValue: controller.eventDetailErrorStreamValue,
          builder: (context, error) {
            return StreamValueBuilder<TenantAdminEvent?>(
              streamValue: controller.eventDetailStreamValue,
              builder: (context, detailedEvent) {
                if (detailedEvent != null) {
                  return TenantAdminEventFormScreen(
                    existingEvent: _eventWithOccurrenceFirst(
                      detailedEvent,
                      selectedOccurrenceId,
                    ),
                  );
                }

                if (isLoading) {
                  return Scaffold(
                    appBar: AppBar(title: Text('Editar evento')),
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (error != null && error.isNotEmpty) {
                  return Scaffold(
                    appBar: AppBar(title: const Text('Editar evento')),
                    body: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Falha ao carregar o evento',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 12),
                            Text(error),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: () {
                                controller.resetEventDetailState();
                                controller.loadEventDetail(selectedEvent.eventId);
                              },
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return Scaffold(
                  appBar: AppBar(title: Text('Editar evento')),
                  body: Center(child: CircularProgressIndicator()),
                );
              },
            );
          },
        );
      },
    );
  }

  void _syncSelectedEventDetail() {
    final selectedEvent = widget.event;
    if (selectedEvent == null) {
      return;
    }

    final controller = _resolvedController;
    controller.resetEventDetailState();
    controller.loadEventDetail(selectedEvent.eventId);
  }
}

class _UnavailableScaffold extends StatelessWidget {
  const _UnavailableScaffold({
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar evento')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Evento indisponível',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Esta rota é interna e precisa de um evento selecionado na lista.',
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: onBack,
                child: const Text('Voltar para eventos'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

TenantAdminEvent _eventWithOccurrenceFirst(
  TenantAdminEvent event,
  String? selectedOccurrenceId,
) {
  if (selectedOccurrenceId == null || selectedOccurrenceId.isEmpty) {
    return event;
  }

  final selectedIndex = event.occurrences.indexWhere(
    (occurrence) => occurrence.occurrenceId == selectedOccurrenceId,
  );
  if (selectedIndex <= 0) {
    return event;
  }

  final selectedOccurrence = event.occurrences[selectedIndex];

  return TenantAdminEvent(
    eventIdValue: event.eventIdValue,
    slugValue: event.slugValue,
    titleValue: event.titleValue,
    contentValue: event.contentValue,
    type: event.type,
    occurrences: [
      selectedOccurrence,
      ...event.occurrences.where(
        (occurrence) => occurrence.occurrenceId != selectedOccurrenceId,
      ),
    ],
    publication: event.publication,
    location: event.location,
    placeRef: event.placeRef,
    thumbUrlValue: event.thumbUrlValue,
    venueDisplayNameValue: event.venueDisplayNameValue,
    relatedAccountProfileIdValues: event.relatedAccountProfileIds,
    relatedAccountProfiles: event.relatedAccountProfiles,
    eventParties: event.eventParties,
    profileGroups: event.profileGroups,
    taxonomyTerms: event.taxonomyTerms,
    createdAtValue: event.createdAtValue,
    updatedAtValue: event.updatedAtValue,
    deletedAtValue: event.deletedAtValue,
  );
}
