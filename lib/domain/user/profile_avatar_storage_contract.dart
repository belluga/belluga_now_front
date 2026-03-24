typedef ProfileAvatarStorageContractPrimString = String;
typedef ProfileAvatarStorageContractPrimInt = int;
typedef ProfileAvatarStorageContractPrimBool = bool;
typedef ProfileAvatarStorageContractPrimDouble = double;
typedef ProfileAvatarStorageContractPrimDateTime = DateTime;
typedef ProfileAvatarStorageContractPrimDynamic = dynamic;

abstract class ProfileAvatarStorageContract {
  Future<ProfileAvatarStorageContractPrimString?> readAvatarPath();
  Future<void> writeAvatarPath(ProfileAvatarStorageContractPrimString path);
  Future<void> clearAvatarPath();
}
