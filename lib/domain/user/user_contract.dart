import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/domain/user/user_profile_contract.dart';
import 'package:platform_device_id_plus/platform_device_id.dart';
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
    currentDeviceId =
        "${BellugaConstants.settings.platform}_${PlatformDeviceId.getDeviceId}";
  }

  Future<void> updateCustomData(Map<String, Object?> newCustomData) {
    customData = newCustomData;

    return Future.value();
  }
}
