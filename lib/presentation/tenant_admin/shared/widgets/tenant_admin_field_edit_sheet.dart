import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TenantAdminFieldEditSheetResult {
  const TenantAdminFieldEditSheetResult({
    required this.value,
  });

  final String value;
}

Future<TenantAdminFieldEditSheetResult?> showTenantAdminFieldEditSheet({
  required BuildContext context,
  required String title,
  required String label,
  required String initialValue,
  String? helperText,
  String confirmLabel = 'Salvar',
  TextInputType keyboardType = TextInputType.text,
  TextInputAction textInputAction = TextInputAction.done,
  TextCapitalization textCapitalization = TextCapitalization.none,
  bool autocorrect = false,
  bool enableSuggestions = false,
  List<TextInputFormatter>? inputFormatters,
  String? Function(String?)? validator,
}) {
  return showModalBottomSheet<TenantAdminFieldEditSheetResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return _TenantAdminFieldEditSheet(
        title: title,
        label: label,
        initialValue: initialValue,
        helperText: helperText,
        confirmLabel: confirmLabel,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        autocorrect: autocorrect,
        enableSuggestions: enableSuggestions,
        inputFormatters: inputFormatters,
        validator: validator,
      );
    },
  );
}

class _TenantAdminFieldEditSheet extends StatefulWidget {
  const _TenantAdminFieldEditSheet({
    required this.title,
    required this.label,
    required this.initialValue,
    required this.helperText,
    required this.confirmLabel,
    required this.keyboardType,
    required this.textInputAction,
    required this.textCapitalization,
    required this.autocorrect,
    required this.enableSuggestions,
    required this.inputFormatters,
    required this.validator,
  });

  final String title;
  final String label;
  final String initialValue;
  final String? helperText;
  final String confirmLabel;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final bool enableSuggestions;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  @override
  State<_TenantAdminFieldEditSheet> createState() =>
      _TenantAdminFieldEditSheetState();
}

class _TenantAdminFieldEditSheetState extends State<_TenantAdminFieldEditSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
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
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    context.router.maybePop(
      TenantAdminFieldEditSheetResult(value: _controller.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _controller,
              autofocus: true,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              textCapitalization: widget.textCapitalization,
              autocorrect: widget.autocorrect,
              enableSuggestions: widget.enableSuggestions,
              inputFormatters: widget.inputFormatters,
              validator: widget.validator,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: widget.label,
                helperText: widget.helperText,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save_outlined),
                label: Text(widget.confirmLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
