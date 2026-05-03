import 'package:flutter/material.dart';

class RenameGroupDialog extends StatefulWidget {
  const RenameGroupDialog({
    super.key,
    required this.initialName,
  });

  final String initialName;

  @override
  State<RenameGroupDialog> createState() => _RenameGroupDialogState();
}

class _RenameGroupDialogState extends State<RenameGroupDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Renomear grupo'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Nome'),
      ),
      actions: [
        TextButton(
          onPressed: () => _popDialog(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => _popDialog(context, _controller.text),
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  void _popDialog(BuildContext context, [String? value]) {
    ModalRoute.of(context)?.navigator?.maybePop(value);
  }
}
