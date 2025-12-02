import 'package:flutter/material.dart';
import 'package:stream_value/main.dart';

class ButtonLoading extends StatelessWidget {
  final Function()? onPressed;
  final StreamValue<bool> loadingStatusStreamValue;
  final String label;
  final ButtonStyle? style;

  const ButtonLoading({
    super.key,
    this.onPressed,
    required this.loadingStatusStreamValue,
    this.label = "Submit",
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder(
      streamValue: loadingStatusStreamValue,
      builder: (context, loadingStatus) {
        return ElevatedButton(
          onPressed: onPressed,
          style: style,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (loadingStatus)
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
                    width: loadingStatus ? 24 : 0,
                  ), // Space between icon and text
                  Text(
                    label,
                    style: TextTheme.of(context).titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                  ),
                  if (loadingStatus) SizedBox(width: 32, height: 32),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
