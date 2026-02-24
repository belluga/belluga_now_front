import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_detail_screen/widgets/invite_prompt_card.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_detail_screen/widgets/sent_invites_list.dart';
import 'package:flutter/material.dart';

/// Section showing sent invites status or invite prompt
class InviteStatusSection extends StatelessWidget {
  const InviteStatusSection({
    super.key,
    required this.sentInvites,
    required this.onInvite,
  });

  final List<SentInviteStatus>? sentInvites;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    if (sentInvites == null || sentInvites!.isEmpty) {
      return InvitePromptCard(onInvite: onInvite);
    }

    return SentInvitesList(
      invites: sentInvites!,
      onInviteMore: onInvite,
    );
  }
}
