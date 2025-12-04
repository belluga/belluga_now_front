import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/repositories/tenant_repository_contract.dart';
import 'package:get_it/get_it.dart';

class TenantRepository extends TenantRepositoryContract {

  @override
  AppData get appData => GetIt.I.get<AppData>();
}
