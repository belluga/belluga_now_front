import 'package:flutter/material.dart';

class ButtonLoading extends StatelessWidget {
  final Function()? onPressed;
  final bool isLoading;
  final String label;
  final ButtonStyle? style;

  const ButtonLoading({
    super.key,
    this.onPressed,
    required this.isLoading,
    this.label = "Submit",
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedForegroundColor =
        style?.foregroundColor?.resolve(<WidgetState>{}) ??
            Theme.of(context).colorScheme.onPrimary;

    return ElevatedButton(
      onPressed: onPressed,
      style: style,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            SizedBox(
              width: 14,
              height: 14,
              child: Center(
                child: CircularProgressIndicator(
                  color: resolvedForegroundColor,
                  strokeWidth: 4,
                ),
              ),
            ),
          if (isLoading) const SizedBox(width: 24),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextTheme.of(context).titleMedium?.copyWith(
                      color: resolvedForegroundColor,
                    ),
              ),
            ),
          ),
          if (isLoading) const SizedBox(width: 32, height: 32),
        ],
      ),
    );
  }
}
