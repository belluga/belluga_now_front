import 'package:flutter/material.dart';

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

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Confirmação'),
        content: Text(
          'Alerta: vamos deletar $projectionCount projeções de $typeLabel.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      );
    },
  );

  return confirmed == true;
}
