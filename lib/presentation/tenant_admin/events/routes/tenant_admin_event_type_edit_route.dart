import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/presentation/tenant_admin/events/screens/tenant_admin_event_type_form_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminEventTypeEditRoute')
class TenantAdminEventTypeEditRoutePage extends StatelessWidget {
  const TenantAdminEventTypeEditRoutePage({
    this.type,
    super.key,
  });

  final TenantAdminEventType? type;

  @override
  Widget build(BuildContext context) {
    final resolvedType = type;
    if (resolvedType == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar tipo de evento')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Tipo de evento indisponível',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Esta rota é interna e precisa de um tipo selecionado na lista.',
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    context.router.replace(const TenantAdminEventTypesRoute());
                  },
                  child: const Text('Voltar para tipos de evento'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return TenantAdminEventTypeFormScreen(existingType: resolvedType);
  }
}
