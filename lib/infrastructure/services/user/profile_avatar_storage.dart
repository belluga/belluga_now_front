import 'package:belluga_now/domain/user/profile_avatar_storage_contract.dart';
import 'package:belluga_now/domain/user/value_objects/profile_avatar_path_value.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProfileAvatarStorage implements ProfileAvatarStorageContract {
  static const String _avatarStorageKey = 'profile_avatar_path';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  Future<ProfileAvatarPathValue?> readAvatarPath() async {
    final raw = await _storage.read(key: _avatarStorageKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    return ProfileAvatarPathValue.fromRaw(raw);
  }

  @override
  Future<void> writeAvatarPath(ProfileAvatarPathValue path) async {
    await _storage.write(key: _avatarStorageKey, value: path.value);
  }

  @override
  Future<void> clearAvatarPath() async {
    await _storage.delete(key: _avatarStorageKey);
  }
}
