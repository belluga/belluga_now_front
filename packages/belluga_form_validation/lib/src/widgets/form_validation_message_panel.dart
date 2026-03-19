import 'package:flutter/material.dart';

class FormValidationMessagePanel extends StatefulWidget {
  const FormValidationMessagePanel({
    super.key,
    required this.messages,
    this.summarySuffixBuilder,
    required this.expandLabel,
    required this.collapseLabel,
  });

  final List<String> messages;
  final String Function(int remainingCount)? summarySuffixBuilder;
  final String expandLabel;
  final String collapseLabel;

  @override
  State<FormValidationMessagePanel> createState() =>
      _FormValidationMessagePanelState();
}

class _FormValidationMessagePanelState
    extends State<FormValidationMessagePanel> {
  bool _expanded = false;

  @override
  void didUpdateWidget(covariant FormValidationMessagePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messages.join('\n') != widget.messages.join('\n')) {
      _expanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final messages = widget.messages;
    final firstMessage = messages.first;
    final remainingCount = messages.length - 1;
    final summaryText = remainingCount <= 0
        ? firstMessage
        : '$firstMessage ${widget.summarySuffixBuilder?.call(remainingCount) ?? "(+$remainingCount errors)"}';

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                summaryText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onErrorContainer,
                ),
              ),
              if (messages.length > 1) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _expanded = !_expanded;
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: scheme.onErrorContainer,
                  ),
                  child: Text(
                    _expanded ? widget.collapseLabel : widget.expandLabel,
                  ),
                ),
                if (_expanded) ...[
                  const SizedBox(height: 8),
                  for (final message in messages.skip(1)) ...[
                    Text(
                      '• $message',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onErrorContainer,
                      ),
                    ),
                    if (message != messages.last) const SizedBox(height: 4),
                  ],
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
