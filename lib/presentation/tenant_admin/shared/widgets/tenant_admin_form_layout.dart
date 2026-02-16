import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

class TenantAdminFormScaffold extends StatelessWidget {
  const TenantAdminFormScaffold({
    super.key,
    required this.title,
    required this.child,
    this.onClose,
    this.closeTooltip = 'Fechar',
    this.showHandle = true,
    this.maxContentWidth = 760,
  });

  final String title;
  final Widget child;
  final VoidCallback? onClose;
  final String closeTooltip;
  final bool showHandle;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final bottomSafeArea = mediaQuery.padding.bottom;
    final contentBottomPadding =
        16 + math.max(bottomInset, bottomSafeArea).toDouble();

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  if (showHandle) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ] else
                    const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: closeTooltip,
                          onPressed: onClose ?? () => context.router.maybePop(),
                          icon: const Icon(Icons.close),
                        ),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: colorScheme.outlineVariant,
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        contentBottomPadding,
                      ),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TenantAdminFormSectionCard extends StatelessWidget {
  const TenantAdminFormSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.description,
  });

  final String title;
  final String? description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (description != null && description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

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
