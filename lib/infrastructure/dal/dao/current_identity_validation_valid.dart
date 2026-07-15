import 'package:belluga_now/infrastructure/dal/dao/current_identity_validation_result.dart';
import 'package:belluga_now/infrastructure/user/dtos/user_dto.dart';

class CurrentIdentityValidationValid extends CurrentIdentityValidationResult {
  const CurrentIdentityValidationValid(this.user);

  final UserDto user;
}
