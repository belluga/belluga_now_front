import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Banner shown when the user has confirmed presence
class ConfirmedBanner extends StatelessWidget {
  const ConfirmedBanner({
    super.key,
    required this.confirmedAt,
  });

  final DateTime confirmedAt;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dateFormat = DateFormat("d 'de' MMMM 'às' HH:mm", 'pt_BR');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              color: Colors.green.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Você confirmou presença!',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
                Text(
                  'Confirmado em ${dateFormat.format(confirmedAt)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
