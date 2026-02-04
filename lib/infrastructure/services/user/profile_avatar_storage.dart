import 'package:belluga_now/domain/user/profile_avatar_storage_contract.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProfileAvatarStorage implements ProfileAvatarStorageContract {
  static const String _avatarStorageKey = 'profile_avatar_path';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  Future<String?> readAvatarPath() async {
    return _storage.read(key: _avatarStorageKey);
  }

  @override
  Future<void> writeAvatarPath(String path) async {
    await _storage.write(key: _avatarStorageKey, value: path);
  }

  @override
  Future<void> clearAvatarPath() async {
    await _storage.delete(key: _avatarStorageKey);
  }
}
