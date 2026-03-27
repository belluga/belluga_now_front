import 'package:flutter/material.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_confirmation_dialog.dart';

Future<bool> tenantAdminConfirmDisablePoiProjection({
  required BuildContext context,
  required bool shouldConfirm,
  required String typeLabel,
  required Future<int> Function() loadProjectionCount,
}) async {
  if (!shouldConfirm) {
    return true;
  }

  int projectionCount;
  try {
    projectionCount = await loadProjectionCount();
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
    return false;
  }

  if (!context.mounted) {
    return false;
  }

  final confirmed = await showTenantAdminConfirmationDialog(
    context: context,
    title: 'Confirmação',
    message: 'Alerta: vamos deletar $projectionCount projeções de $typeLabel.',
    isDestructive: true,
  );

  return confirmed == true;
}
