import 'package:flutter_laravel_backend_boilerplate/domain/user/user_profile_contract.dart';
import 'package:value_objects/domain/value_objects/mongo_id_value.dart';

abstract class UserContract {
  final MongoIDValue uuidValue;
  final UserProfileContract profile;
  Map<String, Object?>? customData;

  UserContract({
    required this.uuidValue,
    required this.profile,
    this.customData,
  });

  Future<void> updateCustomData(Map<String, Object?> newCustomData) {
    customData = newCustomData;

    return Future.value();
  }
}
