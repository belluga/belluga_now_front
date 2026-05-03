import 'package:belluga_now/domain/user/self_profile.dart';
import 'package:belluga_now/domain/auth/value_objects/auth_phone_otp_phone_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_account_profile_id_value.dart';
import 'package:belluga_now/domain/user/value_objects/self_profile_confirmed_events_count_value.dart';
import 'package:belluga_now/domain/user/value_objects/self_profile_pending_invites_count_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_avatar_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_display_name_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_id_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_timezone_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';

class SelfProfileDto {
  const SelfProfileDto({
    required this.userId,
    required this.accountProfileId,
    required this.displayName,
    required this.bio,
    required this.phone,
    required this.avatarUrl,
    required this.pendingInvitesCount,
    required this.confirmedEventsCount,
    required this.timezone,
  });

  final String userId;
  final String accountProfileId;
  final String displayName;
  final String bio;
  final String phone;
  final String? avatarUrl;
  final int pendingInvitesCount;
  final int confirmedEventsCount;
  final String? timezone;

  factory SelfProfileDto.fromJson(Map<String, dynamic> json) {
    final counters =
        json['counters'] is Map<String, dynamic> ? json['counters'] as Map<String, dynamic> : const <String, dynamic>{};
    return SelfProfileDto(
      userId: json['user_id']?.toString().trim() ?? '',
      accountProfileId: json['account_profile_id']?.toString().trim() ?? '',
      displayName: json['display_name']?.toString().trim() ?? '',
      bio: json['bio']?.toString() ?? '',
      phone: json['phone']?.toString().trim() ?? '',
      avatarUrl: json['avatar_url']?.toString().trim().isNotEmpty == true
          ? json['avatar_url']?.toString().trim()
          : null,
      pendingInvitesCount: _parseCounter(counters['pending_invites']),
      confirmedEventsCount: _parseCounter(counters['confirmed_events']),
      timezone: json['timezone']?.toString().trim().isNotEmpty == true
          ? json['timezone']?.toString().trim()
          : null,
    );
  }

  SelfProfile toDomain() {
    final userIdValue = UserIdValue()..parse(userId);
    final accountProfileIdValue = InviteAccountProfileIdValue(
      isRequired: false,
      minLenght: null,
    );
    if (accountProfileId.trim().isNotEmpty) {
      accountProfileIdValue.parse(accountProfileId);
    }
    final displayNameValue =
        UserDisplayNameValue(isRequired: false, minLenght: null)
          ..parse(displayName);
    final bioValue = DescriptionValue(defaultValue: '', minLenght: null)
      ..parse(bio);
    final phoneValue =
        AuthPhoneOtpPhoneValue(isRequired: false, minLenght: null)
          ..parse(phone);
    final avatarValue = UserAvatarValue();
    final avatarUrlRaw = avatarUrl?.trim();
    if (avatarUrlRaw != null && avatarUrlRaw.isNotEmpty) {
      avatarValue.parse(avatarUrlRaw);
    }
    final pendingInvitesCountValue = SelfProfilePendingInvitesCountValue()
      ..set(pendingInvitesCount);
    final confirmedEventsCountValue = SelfProfileConfirmedEventsCountValue()
      ..set(confirmedEventsCount);
    final timezoneValue = UserTimezoneValue();
    final timezoneRaw = timezone?.trim();
    if (timezoneRaw != null && timezoneRaw.isNotEmpty) {
      timezoneValue.parse(timezoneRaw);
    }

    return SelfProfile(
      userIdValue: userIdValue,
      accountProfileIdValue: accountProfileIdValue,
      displayNameValue: displayNameValue,
      bioValue: bioValue,
      phoneValue: phoneValue,
      avatarValue: avatarValue,
      pendingInvitesCountValue: pendingInvitesCountValue,
      confirmedEventsCountValue: confirmedEventsCountValue,
      timezoneValue: timezoneValue,
    );
  }

  static int _parseCounter(dynamic raw) {
    if (raw is int) {
      return raw;
    }
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }
}
