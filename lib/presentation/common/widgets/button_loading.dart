import 'package:flutter/material.dart';
import 'package:stream_value/main.dart';

class ButtonLoading extends StatelessWidget {
  final Function()? onPressed;
  final StreamValue<bool> loadingStatusStreamValue;
  final String label;

  const ButtonLoading({
    super.key,
    this.onPressed,
    required this.loadingStatusStreamValue,
    this.label = "Submit",
  });

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder(
      streamValue: loadingStatusStreamValue,
      builder: (context, loadingStatus) {
        return ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 5,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (loadingStatus)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.inversePrimary,
                          strokeWidth: 4,
                        ),
                      ),
                    ),
                  SizedBox(
                    width: loadingStatus ? 16 : 0,
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
