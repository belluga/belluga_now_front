import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/repositories/account_profiles_repository_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';
import 'package:meta/meta.dart';

class AccountProfileDetailRouteResolver
    implements RouteModelResolver<AccountProfileModel> {
  AccountProfileDetailRouteResolver({
    @visibleForTesting
    AccountProfilesRepositoryContract? accountProfilesRepository,
  }) : _accountProfilesRepository = accountProfilesRepository ??
            GetIt.I.get<AccountProfilesRepositoryContract>();

  final AccountProfilesRepositoryContract _accountProfilesRepository;

  @override
  Future<AccountProfileModel> resolve(RouteResolverParams params) async {
    final slug = params['slug'] as String?;
    if (slug == null || slug.trim().isEmpty) {
      throw ArgumentError.value(
        slug,
        'slug',
        'Account profile slug must be provided',
      );
    }

    final accountProfile =
        await _accountProfilesRepository.getAccountProfileBySlug(slug.trim());
    if (accountProfile == null) {
      throw Exception('Account profile not found for slug: $slug');
    }

    return accountProfile;
  }
}
