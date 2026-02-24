import 'package:flutter/material.dart';

class InviteSharePlusAvatar extends StatelessWidget {
  const InviteSharePlusAvatar(
    this.count, {
    super.key,
    this.isEmptySlot = false,
  });

  final int count;
  final bool isEmptySlot;

  @override
  Widget build(BuildContext context) {
    final bgColor = isEmptySlot
        ? Colors.grey.withValues(alpha: 0.1)
        : Colors.grey.withValues(alpha: 0.2);
    final borderColor = Colors.grey.withValues(alpha: 0.5);

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
              ? Icon(
                  Icons.person_outline,
                  size: 16,
                  color: Colors.grey.withValues(alpha: 0.8),
                )
              : Text(
                  '+$count',
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
        ),
      ),
    );
  }
}
