import 'package:belluga_now/domain/user/self_profile.dart';
import 'package:belluga_now/domain/user/user_profile_media_upload.dart';
import 'package:belluga_now/domain/user/value_objects/user_display_name_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_timezone_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class SelfProfileRepositoryContract {
  final currentProfileStreamValue =
      StreamValue<SelfProfile?>(defaultValue: null);

  Future<SelfProfile> fetchCurrentProfile();

  Future<SelfProfile> refreshCurrentProfile() async {
    final profile = await fetchCurrentProfile();
    currentProfileStreamValue.addValue(profile);
    return profile;
  }

  Future<SelfProfile> updateCurrentProfile({
    UserDisplayNameValue? displayNameValue,
    DescriptionValue? bioValue,
    UserTimezoneValue? timezoneValue,
    UserProfileMediaUpload? avatarUpload,
    DomainBooleanValue? removeAvatarValue,
  });
}
