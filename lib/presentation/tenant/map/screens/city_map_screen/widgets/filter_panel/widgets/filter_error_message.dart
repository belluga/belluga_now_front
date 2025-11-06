import 'package:flutter/material.dart';

class FilterErrorMessage extends StatelessWidget {
  const FilterErrorMessage({
    super.key,
    required this.theme,
  });

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: scheme.error,
          ),
          const SizedBox(width: 12),
          Flexible(
            fit: FlexFit.loose,
            child: Text(
              'Nao foi possivel carregar os filtros neste momento.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
