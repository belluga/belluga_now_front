import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/projections/partner_profile_config.dart';

abstract class PartnerProfileContentRepositoryContract {
  Map<ProfileModuleId, Object?> loadModulesForPartner(
    AccountProfileModel partner,
  );
}
