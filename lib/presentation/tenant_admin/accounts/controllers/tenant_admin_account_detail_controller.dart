import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profiles_controller.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:stream_value/core/stream_value.dart';

class TenantAdminAccountDetailController implements Disposable {
  TenantAdminAccountDetailController({
    TenantAdminAccountProfilesController? delegate,
  }) : _delegate =
            delegate ?? GetIt.I.get<TenantAdminAccountProfilesController>();

  final TenantAdminAccountProfilesController _delegate;

  StreamValue<TenantAdminAccount?> get accountStreamValue =>
      _delegate.accountStreamValue;
  StreamValue<TenantAdminAccountProfile?> get accountProfileStreamValue =>
      _delegate.accountProfileStreamValue;
  StreamValue<List<TenantAdminProfileTypeDefinition>>
      get profileTypesStreamValue => _delegate.profileTypesStreamValue;
  StreamValue<bool> get accountDetailLoadingStreamValue =>
      _delegate.accountDetailLoadingStreamValue;
  StreamValue<String?> get accountDetailErrorStreamValue =>
      _delegate.accountDetailErrorStreamValue;

  Future<void> loadAccountDetail(String accountSlug) {
    return _delegate.loadAccountDetail(accountSlug);
  }

  Future<TenantAdminAccount?> updateAccount({
    required String accountSlug,
    String? name,
    String? slug,
  }) {
    return _delegate.updateAccount(
      accountSlug: accountSlug,
      name: name,
      slug: slug,
    );
  }

  void resetAccountDetail() {
    _delegate.resetAccountDetail();
  }

  @override
  void onDispose() {}
}
