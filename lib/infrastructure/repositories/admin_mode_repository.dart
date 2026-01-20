import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stream_value/core/stream_value.dart';

class AdminModeRepository implements AdminModeRepositoryContract {
  static const String _storageKey = 'active_mode';
  static const String _userValue = 'user';
  static const String _landlordValue = 'landlord';

  final StreamValue<AdminMode> _modeStreamValue =
      StreamValue<AdminMode>(defaultValue: AdminMode.user);

  static FlutterSecureStorage get storage => FlutterSecureStorage();

  @override
  StreamValue<AdminMode> get modeStreamValue => _modeStreamValue;

  @override
  AdminMode get mode => _modeStreamValue.value ?? AdminMode.user;

  @override
  bool get isLandlordMode => mode == AdminMode.landlord;

  @override
  Future<void> init() async {
    final stored = await storage.read(key: _storageKey);
    if (stored == _landlordValue) {
      _modeStreamValue.addValue(AdminMode.landlord);
      return;
    }
    _modeStreamValue.addValue(AdminMode.user);
  }

  @override
  Future<void> setUserMode() async {
    _modeStreamValue.addValue(AdminMode.user);
    await storage.write(key: _storageKey, value: _userValue);
  }

  @override
  Future<void> setLandlordMode() async {
    _modeStreamValue.addValue(AdminMode.landlord);
    await storage.write(key: _storageKey, value: _landlordValue);
  }
}
