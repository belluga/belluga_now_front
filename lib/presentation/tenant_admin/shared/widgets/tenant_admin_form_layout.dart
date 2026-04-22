export 'tenant_admin_form_section_card.dart';
export 'tenant_admin_primary_form_action.dart';

import 'dart:math' as math;

import 'package:belluga_now/application/router/support/route_back_policy.dart';
import 'package:flutter/material.dart';

class TenantAdminFormScaffold extends StatelessWidget {
  const TenantAdminFormScaffold({
    super.key,
    required this.title,
    required this.child,
    required this.closePolicy,
    this.closeTooltip = 'Fechar',
    this.showHandle = true,
    this.maxContentWidth = 760,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  final String title;
  final Widget child;
  final RouteBackPolicy closePolicy;
  final String closeTooltip;
  final bool showHandle;
  final double maxContentWidth;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

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
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
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
                          onPressed: closePolicy.handleBack,
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
                  Divider(height: 1, color: colorScheme.outlineVariant),
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
