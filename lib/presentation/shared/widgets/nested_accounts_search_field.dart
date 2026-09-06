import 'dart:async';

import 'package:flutter/material.dart';

class NestedAccountsSearchField extends StatelessWidget {
  const NestedAccountsSearchField({
    required this.fieldKey,
    required this.onSubmitted,
    super.key,
  });

  final Key fieldKey;
  final Future<void> Function(String search) onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        key: fieldKey,
        onSubmitted: (search) => unawaited(onSubmitted(search)),
        textInputAction: TextInputAction.search,
        decoration: const InputDecoration(
          labelText: 'Buscar neste grupo',
          prefixIcon: Icon(Icons.search),
        ),
      ),
    );
  }
}
