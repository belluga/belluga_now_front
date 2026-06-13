import 'package:flutter/material.dart';

class InviteInfoRow extends StatelessWidget {
  const InviteInfoRow({
    super.key,
    required this.icon,
    required this.text,
    this.maxLines,
    this.color,
  });

  final IconData icon;
  final String text;
  final int? maxLines;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? Colors.white;
    return Row(
      children: [
        Icon(icon, color: resolvedColor, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: resolvedColor),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
