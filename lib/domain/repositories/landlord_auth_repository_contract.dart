typedef LandlordAuthRepositoryContractPrimString = String;
typedef LandlordAuthRepositoryContractPrimInt = int;
typedef LandlordAuthRepositoryContractPrimBool = bool;
typedef LandlordAuthRepositoryContractPrimDouble = double;
typedef LandlordAuthRepositoryContractPrimDateTime = DateTime;
typedef LandlordAuthRepositoryContractPrimDynamic = dynamic;

abstract class LandlordAuthRepositoryContract {
  LandlordAuthRepositoryContractPrimBool get hasValidSession;

  LandlordAuthRepositoryContractPrimString get token;

  Future<void> init();

  Future<void> loginWithEmailPassword(
      LandlordAuthRepositoryContractPrimString email,
      LandlordAuthRepositoryContractPrimString password);

  Future<void> logout();
}
