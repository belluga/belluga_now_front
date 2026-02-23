import 'package:belluga_now/domain/repositories/landlord_tenants_repository_contract.dart';
import 'package:flutter/material.dart';

class TenantSelectionGate extends StatelessWidget {
  const TenantSelectionGate({
    super.key,
    required this.tenants,
    required this.onSelectTenant,
  });

  final List<LandlordTenantOption> tenants;
  final void Function(String tenantDomain) onSelectTenant;

  String _tenantSemanticsIdentifier(String domain) {
    final normalized = domain.trim().toLowerCase();
    final safe = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return 'tenant_selection_option_$safe';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget surface({required Widget child}) {
      return Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: child,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar tenant'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(
            'Escolha o tenant que você deseja administrar. '
            'As operações de itens serão executadas no domínio selecionado.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (tenants.isEmpty)
            surface(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Nenhum tenant disponível no bootstrap atual.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          else
            ...tenants.map(
              (tenant) => surface(
                child: Semantics(
                  identifier: _tenantSemanticsIdentifier(tenant.mainDomain),
                  button: true,
                  onTap: () => onSelectTenant(tenant.mainDomain),
                  child: ListTile(
                    leading: const Icon(Icons.apartment_outlined),
                    title: Text(tenant.name),
                    subtitle: Text(tenant.mainDomain),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onSelectTenant(tenant.mainDomain),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
