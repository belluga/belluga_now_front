import 'package:belluga_now/domain/auth/value_objects/auth_phone_otp_phone_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_account_profile_id_value.dart';
import 'package:belluga_now/domain/user/value_objects/self_profile_confirmed_events_count_value.dart';
import 'package:belluga_now/domain/user/value_objects/self_profile_pending_invites_count_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_avatar_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_display_name_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_id_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_timezone_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';

class SelfProfile {
  SelfProfile({
    required this.userIdValue,
    InviteAccountProfileIdValue? accountProfileIdValue,
    UserDisplayNameValue? displayNameValue,
    DescriptionValue? bioValue,
    AuthPhoneOtpPhoneValue? phoneValue,
    UserAvatarValue? avatarValue,
    SelfProfilePendingInvitesCountValue? pendingInvitesCountValue,
    SelfProfileConfirmedEventsCountValue? confirmedEventsCountValue,
    UserTimezoneValue? timezoneValue,
  })  : accountProfileIdValue =
            accountProfileIdValue ??
                InviteAccountProfileIdValue(
                  isRequired: false,
                  minLenght: null,
                ),
        displayNameValue =
            displayNameValue ?? UserDisplayNameValue(isRequired: false, minLenght: null),
        bioValue = bioValue ?? DescriptionValue(defaultValue: '', minLenght: null),
        phoneValue = phoneValue ?? AuthPhoneOtpPhoneValue(isRequired: false, minLenght: null),
        avatarValue = avatarValue ?? UserAvatarValue(),
        pendingInvitesCountValue =
            pendingInvitesCountValue ?? SelfProfilePendingInvitesCountValue(),
        confirmedEventsCountValue =
            confirmedEventsCountValue ?? SelfProfileConfirmedEventsCountValue(),
        timezoneValue = timezoneValue ?? UserTimezoneValue();

  final UserIdValue userIdValue;
  final InviteAccountProfileIdValue accountProfileIdValue;
  final UserDisplayNameValue displayNameValue;
  final DescriptionValue bioValue;
  final AuthPhoneOtpPhoneValue phoneValue;
  final UserAvatarValue avatarValue;
  final SelfProfilePendingInvitesCountValue pendingInvitesCountValue;
  final SelfProfileConfirmedEventsCountValue confirmedEventsCountValue;
  final UserTimezoneValue timezoneValue;

  String get userId => userIdValue.value;
  String get accountProfileId => accountProfileIdValue.value;
  String get displayName => displayNameValue.value;
  String get bio => bioValue.value;
  String get phone => phoneValue.value;
  String? get avatarUrl => avatarValue.value?.toString();
  int get pendingInvitesCount => pendingInvitesCountValue.value;
  int get confirmedEventsCount => confirmedEventsCountValue.value;
  String? get timezone => timezoneValue.value.trim().isEmpty ? null : timezoneValue.value;
}
