import 'package:flutter/material.dart';

class TenantAdminPrimaryFormAction extends StatelessWidget {
  const TenantAdminPrimaryFormAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.buttonKey,
    this.isLoading = false,
    this.loadingLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Key? buttonKey;
  final bool isLoading;
  final String? loadingLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;
    final effectiveLabel = isLoading ? (loadingLabel ?? label) : label;

    return SizedBox(
      width: double.infinity,
      child: icon == null
          ? FilledButton(
              key: buttonKey,
              onPressed: effectiveOnPressed,
              child: isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        ),
                        const SizedBox(width: 10),
                        Text(effectiveLabel),
                      ],
                    )
                  : Text(effectiveLabel),
            )
          : isLoading
              ? FilledButton(
                  key: buttonKey,
                  onPressed: effectiveOnPressed,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      ),
                      const SizedBox(width: 10),
                      Text(effectiveLabel),
                    ],
                  ),
                )
              : FilledButton.icon(
                  key: buttonKey,
                  onPressed: effectiveOnPressed,
                  icon: Icon(icon),
                  label: Text(effectiveLabel),
                ),
    );
  }
}
