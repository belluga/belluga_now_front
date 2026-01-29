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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final leftContent = leftWidget ?? _buildLeftContent(context);
    final rightContent = rightWidget ?? _buildButton(context);

    if (leftContent == null && rightContent == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (leftContent != null)
              Expanded(flex: 4, child: leftContent),
            if (leftContent != null && rightContent != null)
              const SizedBox(width: 12),
            if (rightContent != null)
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: rightContent,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget? _buildLeftContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final titleStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      color: colorScheme.onSurface,
    );
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w500,
      color: colorScheme.onSurface.withValues(alpha: 0.78),
    );

    if (leftTitle == null && leftSubtitle == null && leftIcon == null) {
      return null;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leftIcon != null) ...[
          Icon(
            leftIcon,
            color: leftIconColor ?? colorScheme.primary,
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
                  style: titleStyle,
                ),
              if (leftSubtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  leftSubtitle!,
                  style: subtitleStyle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget? _buildButton(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (buttonText == null) return null;

    final background = buttonColor ?? colorScheme.primary;
    final foreground =
        background == colorScheme.primary ? colorScheme.onPrimary : colorScheme.onSecondary;

    return ElevatedButton(
      onPressed: onActionPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (buttonIcon != null) ...[
            Icon(buttonIcon, size: 18),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              buttonText!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
