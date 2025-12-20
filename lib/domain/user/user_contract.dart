import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/domain/user/user_profile_contract.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

abstract class UserContract {
  final MongoIDValue uuidValue;
  late String currentDeviceId;
  final UserProfileContract profile;
  Map<String, Object?>? customData;

  UserContract({
    required this.uuidValue,
    required this.profile,
    this.customData,
  }) {
    _setDeviceId();
  }

  Future<void> _setDeviceId() async {
    // NOTE: Avoid `platform_device_id_*` plugins to keep Flutter Web WASM builds compatible.
    // A stable device identifier can be added later once a wasm-safe strategy is defined.
    currentDeviceId = '${BellugaConstants.settings.platform}_unkn';
  }

  Future<void> updateCustomData(Map<String, Object?> newCustomData) {
    customData = newCustomData;

    return Future.value();
  }
}
