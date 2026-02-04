abstract class ProfileAvatarStorageContract {
  Future<String?> readAvatarPath();
  Future<void> writeAvatarPath(String path);
  Future<void> clearAvatarPath();
}
