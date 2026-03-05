import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';

Future<bool> showTenantAdminConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
  String cancelLabel = 'Cancelar',
  bool isDestructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final scheme = Theme.of(dialogContext).colorScheme;
      final destructiveStyle = FilledButton.styleFrom(
        backgroundColor: scheme.error,
        foregroundColor: scheme.onError,
      );

      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => _closeDialog(dialogContext, false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            style: isDestructive ? destructiveStyle : null,
            onPressed: () => _closeDialog(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );

  return confirmed == true;
}

void _closeDialog(BuildContext context, bool value) {
  final routerScope = StackRouterScope.of(context);
  if (routerScope != null) {
    routerScope.controller.maybePop(value);
    return;
  }
  ModalRoute.of(context)?.navigator?.maybePop(value);
}
