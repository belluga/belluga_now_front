import 'package:belluga_now/domain/repositories/self_profile_repository_contract.dart';
import 'package:belluga_now/domain/user/self_profile.dart';
import 'package:belluga_now/domain/user/user_profile_media_upload.dart';
import 'package:belluga_now/domain/user/value_objects/user_display_name_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_timezone_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/self_profile_backend/laravel_self_profile_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/self_profile_backend_contract.dart';

class SelfProfileRepository extends SelfProfileRepositoryContract {
  SelfProfileRepository({SelfProfileBackendContract? backend})
    : _backend = backend ?? LaravelSelfProfileBackend();

  final SelfProfileBackendContract _backend;

  @override
  Future<SelfProfile> fetchCurrentProfile() async {
    final dto = await _backend.fetchCurrentProfile();
    return dto.toDomain();
  }

  @override
  Future<SelfProfile> updateCurrentProfile({
    UserDisplayNameValue? displayNameValue,
    DescriptionValue? bioValue,
    UserTimezoneValue? timezoneValue,
    UserProfileMediaUpload? avatarUpload,
    DomainBooleanValue? removeAvatarValue,
  }) async {
    await _backend.updateCurrentProfile(
      displayNameValue: displayNameValue,
      bioValue: bioValue,
      timezoneValue: timezoneValue,
      avatarUpload: avatarUpload,
      removeAvatarValue: removeAvatarValue,
    );

    final profile = await refreshCurrentProfile();
    return profile;
  }
}
