import 'package:belluga_now/domain/repositories/value_objects/landlord_auth_repository_contract_values.dart';

typedef LandlordAuthRepositoryContractPrimString
    = LandlordAuthRepositoryContractTextValue;
typedef LandlordAuthRepositoryContractPrimInt = int;
typedef LandlordAuthRepositoryContractPrimBool = bool;
typedef LandlordAuthRepositoryContractPrimDouble = double;
typedef LandlordAuthRepositoryContractPrimDateTime = DateTime;
typedef LandlordAuthRepositoryContractPrimDynamic = dynamic;

abstract class LandlordAuthRepositoryContract {
  LandlordAuthRepositoryContractPrimBool get hasValidSession;

  String get token;

  Future<void> init();

  Future<void> loginWithEmailPassword(
    LandlordAuthRepositoryContractTextValue email,
    LandlordAuthRepositoryContractTextValue password,
  );

  Future<void> logout();
}
