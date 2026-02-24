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
    return ElevatedButton(
      onPressed: onPressed,
      style: style,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.secondary,
                      strokeWidth: 4,
                    ),
                  ),
                ),
              SizedBox(
                width: isLoading ? 24 : 0,
              ), // Space between icon and text
              Text(
                label,
                style: TextTheme.of(context).titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
              ),
              if (isLoading) SizedBox(width: 32, height: 32),
            ],
          ),
        ],
      ),
    );
  }
}
