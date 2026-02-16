import 'package:flutter/material.dart';

class TenantAdminDocumentTypeField extends StatefulWidget {
  const TenantAdminDocumentTypeField({
    required this.documentTypeController,
    super.key,
  });

  static const List<String> _documentTypeOptions = <String>[
    'cpf',
    'cnpj',
  ];

  final TextEditingController documentTypeController;

  @override
  State<TenantAdminDocumentTypeField> createState() =>
      _TenantAdminDocumentTypeFieldState();
}

class _TenantAdminDocumentTypeFieldState
    extends State<TenantAdminDocumentTypeField> {
  String? _selectedDocumentType;

  @override
  void initState() {
    super.initState();
    final current = widget.documentTypeController.text.trim();
    _selectedDocumentType = current.isEmpty ? null : current;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedDocumentType,
      decoration: const InputDecoration(labelText: 'Tipo do documento'),
      items: TenantAdminDocumentTypeField._documentTypeOptions
          .map(
            (type) => DropdownMenuItem<String>(
              value: type,
              child: Text(type.toUpperCase()),
            ),
          )
          .toList(growable: false),
      onChanged: (value) {
        setState(() {
          _selectedDocumentType = value;
        });
        widget.documentTypeController.text = value ?? '';
      },
      validator: (value) {
        final current = value ?? widget.documentTypeController.text;
        if (current.trim().isEmpty) {
          return 'Tipo do documento e obrigatorio.';
        }
        return null;
      },
    );
  }
}
