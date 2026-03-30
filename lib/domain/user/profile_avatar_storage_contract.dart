import 'package:belluga_now/domain/user/value_objects/profile_avatar_path_value.dart';

typedef ProfileAvatarStorageContractPrimString = String;
typedef ProfileAvatarStorageContractPrimInt = int;
typedef ProfileAvatarStorageContractPrimBool = bool;
typedef ProfileAvatarStorageContractPrimDouble = double;
typedef ProfileAvatarStorageContractPrimDateTime = DateTime;
typedef ProfileAvatarStorageContractPrimDynamic = dynamic;

abstract class ProfileAvatarStorageContract {
  Future<ProfileAvatarPathValue?> readAvatarPath();
  Future<void> writeAvatarPath(ProfileAvatarPathValue path);
  Future<void> clearAvatarPath();
}
