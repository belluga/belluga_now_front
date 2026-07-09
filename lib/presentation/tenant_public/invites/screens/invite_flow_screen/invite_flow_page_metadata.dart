import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/presentation/shared/web/public_page_metadata_payload.dart';

PublicPageMetadataPayload buildInviteFlowPageMetadata({
  required InviteModel invite,
  required Uri currentUrl,
  required String tenantName,
}) {
  final eventTitle = invite.eventName.trim();
  return PublicPageMetadataPayload(
    title: eventTitle.isEmpty ? tenantName.trim() : eventTitle,
    description: buildInviteFlowPageDescription(
      invite: invite,
      tenantName: tenantName,
    ),
    url: currentUrl.toString(),
    imageUrl: invite.eventImageUrl.trim().isEmpty ? null : invite.eventImageUrl,
  );
}

String buildInviteFlowPageDescription({
  required InviteModel invite,
  required String tenantName,
}) {
  final eventTitle = invite.eventName.trim();
  final inviterName = invite.inviterName?.trim();
  if (inviterName != null && inviterName.isNotEmpty && eventTitle.isNotEmpty) {
    return '$inviterName te convidou para $eventTitle.';
  }

  final hostName = invite.hostName.trim();
  if (hostName.isNotEmpty && eventTitle.isNotEmpty) {
    return 'Convite para $eventTitle em $hostName.';
  }

  if (eventTitle.isNotEmpty) {
    return 'Convite para $eventTitle em ${tenantName.trim()}.';
  }

  return '${tenantName.trim()} web client';
}
