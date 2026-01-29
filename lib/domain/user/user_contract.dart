import 'package:belluga_now/domain/user/user_profile_contract.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';
import 'package:belluga_now/infrastructure/repositories/auth_repository.dart';

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
    currentDeviceId = await AuthRepository.ensureDeviceId();
  }

  Future<void> updateCustomData(Map<String, Object?> newCustomData) {
    customData = newCustomData;

    return Future.value();
  }
}
