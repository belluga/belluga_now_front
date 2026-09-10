import 'package:belluga_now/domain/partners/account_profile_summary.dart';
import 'package:flutter/material.dart';

class InviterNameLabel extends StatelessWidget {
  const InviterNameLabel({
    super.key,
    required this.name,
    required this.accountProfile,
    required this.isPreview,
    this.onTapAccountProfile,
  });

  final String name;
  final AccountProfileSummary? accountProfile;
  final bool isPreview;
  final VoidCallback? onTapAccountProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = Text(
      name,
      style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      textAlign: TextAlign.center,
    );

    if (accountProfile != null && onTapAccountProfile != null) {
      return Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: isPreview ? null : onTapAccountProfile,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: text,
          ),
        ),
      );
    }

    return text;
  }
}
