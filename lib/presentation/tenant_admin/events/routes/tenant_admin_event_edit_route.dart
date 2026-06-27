import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/tenant_admin_module.dart';
import 'package:belluga_now/application/router/support/route_scoped_resolver_route.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/presentation/tenant_admin/events/screens/tenant_admin_event_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'TenantAdminEventEditRoute')
class TenantAdminEventEditRoutePage
    extends RouteScopedResolverRoute<TenantAdminEvent, TenantAdminModule> {
  const TenantAdminEventEditRoutePage({
    super.key,
    @PathParam('eventId') required this.eventId,
    @QueryParam('occurrence') this.occurrenceId,
  });

  final String eventId;
  final String? occurrenceId;

  @override
  RouteResolverParams get resolverParams => {
        'eventId': eventId,
      };

  @override
  Widget buildLoading(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar evento')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  @override
  RouteScopedResolverErrorBuilder get errorBuilder =>
      (context, error, retry) => Scaffold(
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
                    Text(error.toString()),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: retry,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            ),
          );

  @override
  Widget buildScreen(BuildContext context, TenantAdminEvent model) {
    return TenantAdminEventFormScreen(
      existingEvent: _eventWithOccurrenceFirst(
        model,
        occurrenceId?.trim(),
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
