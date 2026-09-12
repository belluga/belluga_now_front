import 'package:flutter/material.dart';

class ImmersiveSectionTitle extends StatelessWidget {
  ImmersiveSectionTitle({
    super.key,
    required this.text,
    this.showDivider = false,
    this.actions,
  }) : assert(text.trim().isNotEmpty, 'text must not be blank');

  final String text;
  final bool showDivider;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final actionWidgets = actions;
    final hasActions = actionWidgets != null && actionWidgets.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Semantics(
              header: true,
              child: Text(
                text,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (hasActions)
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                children: actionWidgets,
              ),
          ],
        ),
        if (showDivider) ...[
          const SizedBox(height: 8),
          Divider(
            height: 1,
            color: Theme.of(context).dividerColor.withValues(alpha: 0.45),
          ),
        ],
      ],
    );
  }
}
