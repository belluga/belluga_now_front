import 'package:flutter/material.dart';

class InvitePlusAvatar extends StatelessWidget {
  const InvitePlusAvatar(this.count, {super.key, this.isEmptySlot = false});

  final int count;
  final bool isEmptySlot;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseOnSurface = colorScheme.onSurface;
    final bgColor = isEmptySlot
        ? baseOnSurface.withValues(alpha: 0.08)
        : baseOnSurface.withValues(alpha: 0.16);
    final borderColor = baseOnSurface.withValues(alpha: 0.28);

    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
          border: Border.all(color: borderColor, style: BorderStyle.solid),
        ),
        child: Center(
          child: isEmptySlot
              ? Icon(Icons.person_outline,
                  size: 16, color: baseOnSurface.withValues(alpha: 0.65))
              : Text(
                  '+$count',
                  style: TextStyle(
                    color: baseOnSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
        ),
      ),
    );
  }
}
