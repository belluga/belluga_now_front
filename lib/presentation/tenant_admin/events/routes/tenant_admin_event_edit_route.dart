import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/presentation/tenant_admin/events/screens/tenant_admin_event_form_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminEventEditRoute')
class TenantAdminEventEditRoutePage extends StatelessWidget {
  const TenantAdminEventEditRoutePage({
    this.event,
    super.key,
  });

  final TenantAdminEvent? event;

  @override
  Widget build(BuildContext context) {
    final resolvedEvent = event;
    if (resolvedEvent == null) {
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
                  onPressed: () {
                    context.router.replace(const TenantAdminEventsRoute());
                  },
                  child: const Text('Voltar para eventos'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return TenantAdminEventFormScreen(existingEvent: resolvedEvent);
  }
}
