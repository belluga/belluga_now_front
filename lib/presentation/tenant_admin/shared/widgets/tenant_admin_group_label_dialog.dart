import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

Future<String?> showTenantAdminGroupLabelDialog({
  required BuildContext context,
  required String title,
  String initialValue = '',
  String confirmLabel = 'Criar grupo',
}) async {
  final created = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return _TenantAdminGroupLabelDialog(
        title: title,
        initialValue: initialValue,
        confirmLabel: confirmLabel,
      );
    },
  );
  final normalized = created?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}

class _TenantAdminGroupLabelDialog extends StatefulWidget {
  const _TenantAdminGroupLabelDialog({
    required this.title,
    required this.initialValue,
    required this.confirmLabel,
  });

  final String title;
  final String initialValue;
  final String confirmLabel;

  @override
  State<_TenantAdminGroupLabelDialog> createState() =>
      _TenantAdminGroupLabelDialogState();
}

class _TenantAdminGroupLabelDialogState
    extends State<_TenantAdminGroupLabelDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final label = _controller.text.trim();
    if (label.isEmpty) {
      return;
    }
    FocusScope.of(context).unfocus();
    context.router.maybePop(label);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nome do grupo',
              hintText: 'Novo grupo',
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => context.router.maybePop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}
