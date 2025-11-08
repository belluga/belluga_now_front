import 'package:belluga_now/domain/invites/invite_partner_summary.dart';
import 'package:flutter/material.dart';

class InviterNameLabel extends StatelessWidget {
  const InviterNameLabel({
    super.key,
    required this.name,
    required this.partner,
    required this.isPreview,
    this.onTapPartner,
  });

  final String name;
  final InvitePartnerSummary? partner;
  final bool isPreview;
  final VoidCallback? onTapPartner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = Text(
      name,
      style: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      textAlign: TextAlign.center,
    );

    if (partner != null && onTapPartner != null) {
      return Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: isPreview ? null : onTapPartner,
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
