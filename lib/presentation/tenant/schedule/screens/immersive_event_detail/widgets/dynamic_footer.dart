import 'package:flutter/material.dart';

class DynamicFooter extends StatelessWidget {
  const DynamicFooter({
    this.leftTitle,
    this.leftSubtitle,
    this.leftIcon,
    this.leftIconColor,
    this.leftWidget,
    this.buttonText,
    this.buttonIcon,
    this.buttonColor,
    this.onActionPressed,
    this.rightWidget,
    super.key,
  });

  final String? leftTitle;
  final String? leftSubtitle;
  final IconData? leftIcon;
  final Color? leftIconColor;
  final Widget? leftWidget;

  final String? buttonText;
  final IconData? buttonIcon;
  final Color? buttonColor;
  final VoidCallback? onActionPressed;
  final Widget? rightWidget;

  @override
  Widget build(BuildContext context) {
    final leftContent = leftWidget ?? _buildLeftContent(context);
    final rightContent = rightWidget ?? _buildButton(context);

    if (leftContent == null && rightContent == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (leftContent != null) Expanded(child: leftContent),
            if (leftContent != null && rightContent != null)
              const SizedBox(width: 12),
            if (rightContent != null) Expanded(child: rightContent),
          ],
        ),
      ),
    );
  }

  Widget? _buildLeftContent(BuildContext context) {
    if (leftTitle == null && leftSubtitle == null && leftIcon == null) {
      return null;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leftIcon != null) ...[
          Icon(
            leftIcon,
            color: leftIconColor ?? Colors.green,
            size: 20,
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leftTitle != null)
                Text(
                  leftTitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (leftSubtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  leftSubtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget? _buildButton(BuildContext context) {
    if (buttonText == null) return null;

    return ElevatedButton(
      onPressed: onActionPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor ?? Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (buttonIcon != null) ...[
            Icon(buttonIcon, size: 18),
            const SizedBox(width: 8),
          ],
          Text(
            buttonText!,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
