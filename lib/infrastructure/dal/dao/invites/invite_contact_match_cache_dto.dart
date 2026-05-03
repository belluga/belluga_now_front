import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/inviteable_reasons.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_account_profile_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_contact_hash_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_contact_type_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_inviter_avatar_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_inviter_name_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_profile_exposure_level_value.dart';
import 'package:belluga_now/domain/invites/value_objects/inviteable_reason_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_id_value.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';

class InviteContactMatchCacheDto {
  const InviteContactMatchCacheDto({
    required this.contactHash,
    required this.type,
    required this.userId,
    required this.receiverAccountProfileId,
    required this.displayName,
    required this.avatarUrl,
    required this.profileExposureLevel,
    required this.inviteableReasons,
    required this.isInviteable,
  });

  final String contactHash;
  final String type;
  final String userId;
  final String receiverAccountProfileId;
  final String displayName;
  final String? avatarUrl;
  final String profileExposureLevel;
  final List<String> inviteableReasons;
  final bool isInviteable;

  factory InviteContactMatchCacheDto.fromDomain(InviteContactMatch match) {
    return InviteContactMatchCacheDto(
      contactHash: match.contactHash,
      type: match.type,
      userId: match.userId,
      receiverAccountProfileId: match.receiverAccountProfileId,
      displayName: match.displayName,
      avatarUrl: match.avatarUrl,
      profileExposureLevel: match.profileExposureLevel,
      inviteableReasons: match.inviteableReasons
          .where((reason) => reason.trim().isNotEmpty)
          .toList(growable: false),
      isInviteable: match.isInviteable,
    );
  }

  factory InviteContactMatchCacheDto.fromJsonMap(Map<String, dynamic> json) {
    return InviteContactMatchCacheDto(
      contactHash: json['contact_hash']?.toString().trim() ?? '',
      type: json['type']?.toString().trim() ?? '',
      userId: json['user_id']?.toString().trim() ?? '',
      receiverAccountProfileId:
          json['receiver_account_profile_id']?.toString().trim() ?? '',
      displayName: json['display_name']?.toString().trim() ?? '',
      avatarUrl: json['avatar_url']?.toString().trim(),
      profileExposureLevel:
          json['profile_exposure_level']?.toString().trim() ?? '',
      inviteableReasons:
          (json['inviteable_reasons'] as List<dynamic>? ?? const [])
              .map((reason) => reason.toString().trim())
              .where((reason) => reason.isNotEmpty)
              .toList(growable: false),
      isInviteable: json['is_inviteable'] == true,
    );
  }

  Map<String, dynamic> toJsonMap() {
    return <String, dynamic>{
      'contact_hash': contactHash,
      'type': type,
      'user_id': userId,
      'receiver_account_profile_id': receiverAccountProfileId,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'profile_exposure_level': profileExposureLevel,
      'inviteable_reasons': inviteableReasons,
      'is_inviteable': isInviteable,
    };
  }

  InviteContactMatch toDomain() {
    final avatarValue = InviteInviterAvatarValue();
    final normalizedAvatar = avatarUrl?.trim();
    if (normalizedAvatar != null && normalizedAvatar.isNotEmpty) {
      avatarValue.parse(normalizedAvatar);
    }

    return InviteContactMatch(
      contactHashValue: InviteContactHashValue()..parse(contactHash),
      typeValue: InviteContactTypeValue()..parse(type),
      userIdValue: UserIdValue()..parse(userId),
      receiverAccountProfileIdValue: InviteAccountProfileIdValue()
        ..parse(receiverAccountProfileId),
      displayNameValue: InviteInviterNameValue()..parse(displayName),
      avatarValue: avatarValue,
      profileExposureLevelValue: InviteProfileExposureLevelValue()
        ..parse(profileExposureLevel),
      inviteableReasons: InviteableReasons(
        inviteableReasons
            .map((reason) => InviteableReasonValue()..parse(reason))
            .toList(growable: false),
      ),
      isInviteableValue: DomainBooleanValue()..parse(isInviteable.toString()),
    );
  }
}
