import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/invites/invite_inviter_type.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:flutter/material.dart';

Future<String?> showInviteCandidatePicker(
  BuildContext context, {
  required InviteModel invite,
  required String actionLabel,
}) async {
  final primaryInviteId = invite.primaryInviteId;
  if (!invite.hasMultipleInviters) {
    return primaryInviteId;
  }

  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$actionLabel com quem te convidou',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                invite.eventName,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              ...invite.inviters.map(
                (candidate) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundImage: candidate.avatarUrl != null &&
                            candidate.avatarUrl!.trim().isNotEmpty
                        ? NetworkImage(candidate.avatarUrl!)
                        : null,
                    child: candidate.avatarUrl == null ||
                            candidate.avatarUrl!.trim().isEmpty
                        ? Text(
                            candidate.name.isNotEmpty
                                ? candidate.name[0].toUpperCase()
                                : '?',
                          )
                        : null,
                  ),
                  title: Text(candidate.name),
                  subtitle: Text(
                    candidate.type.apiValue.replaceAll('_', ' '),
                  ),
                  onTap: () => context.router.pop(candidate.inviteId),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
