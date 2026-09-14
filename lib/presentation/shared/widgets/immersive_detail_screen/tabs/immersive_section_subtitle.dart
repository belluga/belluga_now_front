import 'package:flutter/material.dart';

class ImmersiveSectionSubtitle extends StatelessWidget {
  ImmersiveSectionSubtitle({
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

    return Row(
      children: [
        Flexible(
          child: Semantics(
            header: true,
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        if (showDivider) ...[
          const SizedBox(width: 12),
          Expanded(
            child: Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ],
        if (hasActions) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: actionWidgets,
            ),
          ),
        ],
      ],
    );
  }
}
