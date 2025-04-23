import 'package:flutter/material.dart';
import 'package:stream_value/main.dart';

class ButtonLoading extends StatelessWidget {
  final Function()? onPressed;
  final StreamValue<bool> loadingStatusStreamValue;
  final String label;
  final IconData? icon;

  const ButtonLoading({
    super.key,
    this.onPressed,
    required this.loadingStatusStreamValue,
    this.label = "Submit",
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder(
      streamValue: loadingStatusStreamValue,
      builder: (context, loadingStatus) {
        if (loadingStatus) {
          return Container(
            width: 46,
            height: 46,
            padding: EdgeInsets.all(10),
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
                strokeWidth: 2.0,
              ),
            ),
          );
        }

        return ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) Icon(icon),
              const SizedBox(width: 10),
              Text(label),
            ],
          ),
        );
      },
    );
  }
}
