// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i74;
import 'package:belluga_now/application/router/guards/location_permission_gate_result.dart'
    as _i76;
import 'package:belluga_now/application/router/guards/location_permission_state.dart'
    as _i79;
import 'package:belluga_now/domain/invites/invite_model.dart' as _i78;
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart'
    as _i80;
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart'
    as _i81;
import 'package:belluga_now/presentation/account_workspace/routes/account_workspace_create_event_route.dart'
    as _i2;
import 'package:belluga_now/presentation/account_workspace/routes/account_workspace_home_route.dart'
    as _i3;
import 'package:belluga_now/presentation/account_workspace/routes/account_workspace_scoped_route.dart'
    as _i4;
import 'package:belluga_now/presentation/landlord_area/home/routes/landlord_home_route.dart'
    as _i17;
import 'package:belluga_now/presentation/shared/auth/routes/auth_create_new_password_route.dart'
    as _i6;
import 'package:belluga_now/presentation/shared/auth/routes/auth_login_route.dart'
    as _i7;
import 'package:belluga_now/presentation/shared/auth/routes/recovery_password_route.dart'
    as _i22;
import 'package:belluga_now/presentation/shared/init/routes/init_route.dart'
    as _i13;
import 'package:belluga_now/presentation/shared/location_permission/routes/location_permission_route.dart'
    as _i18;
import 'package:belluga_now/presentation/shared/promotion/routes/app_promotion_route.dart'
    as _i5;
import 'package:belluga_now/presentation/tenant_admin/account_profiles/routes/tenant_admin_account_profile_create_route.dart'
    as _i26;
import 'package:belluga_now/presentation/tenant_admin/account_profiles/routes/tenant_admin_account_profile_edit_route.dart'
    as _i27;
import 'package:belluga_now/presentation/tenant_admin/account_profiles/routes/tenant_admin_account_profile_external_link_add_route.dart'
    as _i28;
import 'package:belluga_now/presentation/tenant_admin/account_profiles/routes/tenant_admin_account_profile_external_link_edit_route.dart'
    as _i29;
import 'package:belluga_now/presentation/tenant_admin/account_profiles/routes/tenant_admin_account_profile_group_members_route.dart'
    as _i30;
import 'package:belluga_now/presentation/tenant_admin/accounts/routes/tenant_admin_account_create_route.dart'
    as _i24;
import 'package:belluga_now/presentation/tenant_admin/accounts/routes/tenant_admin_account_detail_route.dart'
    as _i25;
import 'package:belluga_now/presentation/tenant_admin/accounts/routes/tenant_admin_accounts_list_route.dart'
    as _i31;
import 'package:belluga_now/presentation/tenant_admin/accounts/routes/tenant_admin_location_picker_route.dart'
    as _i42;
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/routes/tenant_admin_discovery_filter_surface_route.dart'
    as _i33;
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/routes/tenant_admin_discovery_filters_route.dart'
    as _i34;
import 'package:belluga_now/presentation/tenant_admin/events/routes/tenant_admin_event_create_route.dart'
    as _i35;
import 'package:belluga_now/presentation/tenant_admin/events/routes/tenant_admin_event_edit_route.dart'
    as _i36;
import 'package:belluga_now/presentation/tenant_admin/events/routes/tenant_admin_event_occurrence_group_members_route.dart'
    as _i37;
import 'package:belluga_now/presentation/tenant_admin/events/routes/tenant_admin_event_type_create_route.dart'
    as _i38;
import 'package:belluga_now/presentation/tenant_admin/events/routes/tenant_admin_event_type_edit_route.dart'
    as _i39;
import 'package:belluga_now/presentation/tenant_admin/events/routes/tenant_admin_event_types_route.dart'
    as _i40;
import 'package:belluga_now/presentation/tenant_admin/events/routes/tenant_admin_events_route.dart'
    as _i41;
import 'package:belluga_now/presentation/tenant_admin/organizations/routes/tenant_admin_organization_create_route.dart'
    as _i43;
import 'package:belluga_now/presentation/tenant_admin/organizations/routes/tenant_admin_organization_detail_route.dart'
    as _i44;
import 'package:belluga_now/presentation/tenant_admin/organizations/routes/tenant_admin_organizations_list_route.dart'
    as _i45;
import 'package:belluga_now/presentation/tenant_admin/profile_types/routes/tenant_admin_profile_type_create_route.dart'
    as _i46;
import 'package:belluga_now/presentation/tenant_admin/profile_types/routes/tenant_admin_profile_type_detail_route.dart'
    as _i47;
import 'package:belluga_now/presentation/tenant_admin/profile_types/routes/tenant_admin_profile_type_edit_route.dart'
    as _i48;
import 'package:belluga_now/presentation/tenant_admin/profile_types/routes/tenant_admin_profile_types_list_route.dart'
    as _i49;
import 'package:belluga_now/presentation/tenant_admin/settings/models/tenant_admin_settings_integration_section.dart'
    as _i82;
import 'package:belluga_now/presentation/tenant_admin/settings/routes/tenant_admin_settings_domains_route.dart'
    as _i50;
import 'package:belluga_now/presentation/tenant_admin/settings/routes/tenant_admin_settings_environment_snapshot_route.dart'
    as _i51;
import 'package:belluga_now/presentation/tenant_admin/settings/routes/tenant_admin_settings_local_preferences_route.dart'
    as _i52;
import 'package:belluga_now/presentation/tenant_admin/settings/routes/tenant_admin_settings_route.dart'
    as _i53;
import 'package:belluga_now/presentation/tenant_admin/settings/routes/tenant_admin_settings_technical_integrations_route.dart'
    as _i54;
import 'package:belluga_now/presentation/tenant_admin/settings/routes/tenant_admin_settings_visual_identity_route.dart'
    as _i55;
import 'package:belluga_now/presentation/tenant_admin/shell/routes/tenant_admin_dashboard_route.dart'
    as _i32;
import 'package:belluga_now/presentation/tenant_admin/shell/routes/tenant_admin_shell_route.dart'
    as _i56;
import 'package:belluga_now/presentation/tenant_admin/static_assets/routes/tenant_admin_static_asset_create_route.dart'
    as _i57;
import 'package:belluga_now/presentation/tenant_admin/static_assets/routes/tenant_admin_static_asset_detail_route.dart'
    as _i58;
import 'package:belluga_now/presentation/tenant_admin/static_assets/routes/tenant_admin_static_asset_edit_route.dart'
    as _i59;
import 'package:belluga_now/presentation/tenant_admin/static_assets/routes/tenant_admin_static_assets_list_route.dart'
    as _i60;
import 'package:belluga_now/presentation/tenant_admin/static_profile_types/routes/tenant_admin_static_profile_type_create_route.dart'
    as _i61;
import 'package:belluga_now/presentation/tenant_admin/static_profile_types/routes/tenant_admin_static_profile_type_detail_route.dart'
    as _i62;
import 'package:belluga_now/presentation/tenant_admin/static_profile_types/routes/tenant_admin_static_profile_type_edit_route.dart'
    as _i63;
import 'package:belluga_now/presentation/tenant_admin/static_profile_types/routes/tenant_admin_static_profile_types_list_route.dart'
    as _i64;
import 'package:belluga_now/presentation/tenant_admin/taxonomies/routes/tenant_admin_taxonomies_list_route.dart'
    as _i65;
import 'package:belluga_now/presentation/tenant_admin/taxonomies/routes/tenant_admin_taxonomy_create_route_page.dart'
    as _i66;
import 'package:belluga_now/presentation/tenant_admin/taxonomies/routes/tenant_admin_taxonomy_edit_route_page.dart'
    as _i67;
import 'package:belluga_now/presentation/tenant_admin/taxonomies/routes/tenant_admin_taxonomy_term_create_route_page.dart'
    as _i68;
import 'package:belluga_now/presentation/tenant_admin/taxonomies/routes/tenant_admin_taxonomy_term_detail_route.dart'
    as _i69;
import 'package:belluga_now/presentation/tenant_admin/taxonomies/routes/tenant_admin_taxonomy_term_edit_route_page.dart'
    as _i70;
import 'package:belluga_now/presentation/tenant_admin/taxonomies/routes/tenant_admin_taxonomy_terms_route.dart'
    as _i71;
import 'package:belluga_now/presentation/tenant_public/discovery/routes/discovery_route.dart'
    as _i10;
import 'package:belluga_now/presentation/tenant_public/home/routes/tenant_home_route.dart'
    as _i72;
import 'package:belluga_now/presentation/tenant_public/invites/routes/contact_group_management_route.dart'
    as _i9;
import 'package:belluga_now/presentation/tenant_public/invites/routes/invite_entry_route.dart'
    as _i14;
import 'package:belluga_now/presentation/tenant_public/invites/routes/invite_flow_route.dart'
    as _i15;
import 'package:belluga_now/presentation/tenant_public/invites/routes/invite_share_route.dart'
    as _i16;
import 'package:belluga_now/presentation/tenant_public/legal/routes/tenant_privacy_policy_route.dart'
    as _i73;
import 'package:belluga_now/presentation/tenant_public/map/routes/city_map_route.dart'
    as _i8;
import 'package:belluga_now/presentation/tenant_public/map/routes/poi_details_route.dart'
    as _i20;
import 'package:belluga_now/presentation/tenant_public/partners/routes/partner_detail_route.dart'
    as _i19;
import 'package:belluga_now/presentation/tenant_public/profile/routes/account_deletion_resolution_route.dart'
    as _i1;
import 'package:belluga_now/presentation/tenant_public/profile/routes/profile_route.dart'
    as _i21;
import 'package:belluga_now/presentation/tenant_public/schedule/routes/event_search_route.dart'
    as _i11;
import 'package:belluga_now/presentation/tenant_public/schedule/routes/immersive_event_detail_route.dart'
    as _i12;
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/models/invite_filter.dart'
    as _i77;
import 'package:belluga_now/presentation/tenant_public/static_assets/routes/static_asset_detail_route.dart'
    as _i23;
import 'package:flutter/material.dart' as _i75;

/// generated route for
/// [_i1.AccountDeletionResolutionRoutePage]
class AccountDeletionResolutionRoute extends _i74.PageRouteInfo<void> {
  const AccountDeletionResolutionRoute({List<_i74.PageRouteInfo>? children})
    : super(AccountDeletionResolutionRoute.name, initialChildren: children);

  static const String name = 'AccountDeletionResolutionRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      return const _i1.AccountDeletionResolutionRoutePage();
    },
  );
}

/// generated route for
/// [_i2.AccountWorkspaceCreateEventRoutePage]
class AccountWorkspaceCreateEventRoute
    extends _i74.PageRouteInfo<AccountWorkspaceCreateEventRouteArgs> {
  AccountWorkspaceCreateEventRoute({
    required String accountSlug,
    _i75.Key? key,
    List<_i74.PageRouteInfo>? children,
  }) : super(
         AccountWorkspaceCreateEventRoute.name,
         args: AccountWorkspaceCreateEventRouteArgs(
           accountSlug: accountSlug,
           key: key,
         ),
         rawPathParams: {'accountSlug': accountSlug},
         initialChildren: children,
       );

  static const String name = 'AccountWorkspaceCreateEventRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<AccountWorkspaceCreateEventRouteArgs>(
        orElse: () => AccountWorkspaceCreateEventRouteArgs(
          accountSlug: pathParams.getString('accountSlug'),
        ),
      );
      return _i2.AccountWorkspaceCreateEventRoutePage(
        accountSlug: args.accountSlug,
        key: args.key,
      );
    },
  );
}

class AccountWorkspaceCreateEventRouteArgs {
  const AccountWorkspaceCreateEventRouteArgs({
    required this.accountSlug,
    this.key,
  });

  final String accountSlug;

  final _i75.Key? key;

  @override
  String toString() {
    return 'AccountWorkspaceCreateEventRouteArgs{accountSlug: $accountSlug, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AccountWorkspaceCreateEventRouteArgs) return false;
    return accountSlug == other.accountSlug && key == other.key;
  }

  @override
  int get hashCode => accountSlug.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i3.AccountWorkspaceHomeRoutePage]
class AccountWorkspaceHomeRoute extends _i74.PageRouteInfo<void> {
  const AccountWorkspaceHomeRoute({List<_i74.PageRouteInfo>? children})
    : super(AccountWorkspaceHomeRoute.name, initialChildren: children);

  static const String name = 'AccountWorkspaceHomeRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      return const _i3.AccountWorkspaceHomeRoutePage();
    },
  );
}

/// generated route for
/// [_i4.AccountWorkspaceScopedRoutePage]
class AccountWorkspaceScopedRoute
    extends _i74.PageRouteInfo<AccountWorkspaceScopedRouteArgs> {
  AccountWorkspaceScopedRoute({
    required String accountSlug,
    _i75.Key? key,
    List<_i74.PageRouteInfo>? children,
  }) : super(
         AccountWorkspaceScopedRoute.name,
         args: AccountWorkspaceScopedRouteArgs(
           accountSlug: accountSlug,
           key: key,
         ),
         rawPathParams: {'accountSlug': accountSlug},
         initialChildren: children,
       );

  static const String name = 'AccountWorkspaceScopedRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<AccountWorkspaceScopedRouteArgs>(
        orElse: () => AccountWorkspaceScopedRouteArgs(
          accountSlug: pathParams.getString('accountSlug'),
        ),
      );
      return _i4.AccountWorkspaceScopedRoutePage(
        accountSlug: args.accountSlug,
        key: args.key,
      );
    },
  );
}

class AccountWorkspaceScopedRouteArgs {
  const AccountWorkspaceScopedRouteArgs({required this.accountSlug, this.key});

  final String accountSlug;

  final _i75.Key? key;

  @override
  String toString() {
    return 'AccountWorkspaceScopedRouteArgs{accountSlug: $accountSlug, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AccountWorkspaceScopedRouteArgs) return false;
    return accountSlug == other.accountSlug && key == other.key;
  }

  @override
  int get hashCode => accountSlug.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i5.AppPromotionRoutePage]
class AppPromotionRoute extends _i74.PageRouteInfo<AppPromotionRouteArgs> {
  AppPromotionRoute({
    _i75.Key? key,
    String? redirectPath,
    List<_i74.PageRouteInfo>? children,
  }) : super(
         AppPromotionRoute.name,
         args: AppPromotionRouteArgs(key: key, redirectPath: redirectPath),
         rawQueryParams: {'redirect': redirectPath},
         initialChildren: children,
       );

  static const String name = 'AppPromotionRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      final queryParams = data.queryParams;
      final args = data.argsAs<AppPromotionRouteArgs>(
        orElse: () => AppPromotionRouteArgs(
          redirectPath: queryParams.optString('redirect'),
        ),
      );
      return _i5.AppPromotionRoutePage(
        key: args.key,
        redirectPath: args.redirectPath,
      );
    },
  );
}

class AppPromotionRouteArgs {
  const AppPromotionRouteArgs({this.key, this.redirectPath});

  final _i75.Key? key;

  final String? redirectPath;

  @override
  String toString() {
    return 'AppPromotionRouteArgs{key: $key, redirectPath: $redirectPath}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AppPromotionRouteArgs) return false;
    return key == other.key && redirectPath == other.redirectPath;
  }

  @override
  int get hashCode => key.hashCode ^ redirectPath.hashCode;
}

/// generated route for
/// [_i6.AuthCreateNewPasswordRoutePage]
class AuthCreateNewPasswordRoute extends _i74.PageRouteInfo<void> {
  const AuthCreateNewPasswordRoute({List<_i74.PageRouteInfo>? children})
    : super(AuthCreateNewPasswordRoute.name, initialChildren: children);

  static const String name = 'AuthCreateNewPasswordRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      return const _i6.AuthCreateNewPasswordRoutePage();
    },
  );
}

/// generated route for
/// [_i7.AuthLoginRoutePage]
class AuthLoginRoute extends _i74.PageRouteInfo<AuthLoginRouteArgs> {
  AuthLoginRoute({
    _i75.Key? key,
    String? redirectPath,
    List<_i74.PageRouteInfo>? children,
  }) : super(
         AuthLoginRoute.name,
         args: AuthLoginRouteArgs(key: key, redirectPath: redirectPath),
         rawQueryParams: {'redirect': redirectPath},
         initialChildren: children,
       );

  static const String name = 'AuthLoginRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      final queryParams = data.queryParams;
      final args = data.argsAs<AuthLoginRouteArgs>(
        orElse: () =>
            AuthLoginRouteArgs(redirectPath: queryParams.optString('redirect')),
      );
      return _i7.AuthLoginRoutePage(
        key: args.key,
        redirectPath: args.redirectPath,
      );
    },
  );
}

class AuthLoginRouteArgs {
  const AuthLoginRouteArgs({this.key, this.redirectPath});

  final _i75.Key? key;

  final String? redirectPath;

  @override
  String toString() {
    return 'AuthLoginRouteArgs{key: $key, redirectPath: $redirectPath}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AuthLoginRouteArgs) return false;
    return key == other.key && redirectPath == other.redirectPath;
  }

  @override
  int get hashCode => key.hashCode ^ redirectPath.hashCode;
}

/// generated route for
/// [_i8.CityMapRoutePage]
class CityMapRoute extends _i74.PageRouteInfo<CityMapRouteArgs> {
  CityMapRoute({
    _i75.Key? key,
    String? poi,
    String? stack,
    _i76.LocationPermissionGateResult? locationGateResult,
    List<_i74.PageRouteInfo>? children,
  }) : super(
         CityMapRoute.name,
         args: CityMapRouteArgs(
           key: key,
           poi: poi,
           stack: stack,
           locationGateResult: locationGateResult,
         ),
         rawQueryParams: {'poi': poi, 'stack': stack},
         initialChildren: children,
       );

  static const String name = 'CityMapRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      final queryParams = data.queryParams;
      final args = data.argsAs<CityMapRouteArgs>(
        orElse: () => CityMapRouteArgs(
          poi: queryParams.optString('poi'),
          stack: queryParams.optString('stack'),
        ),
      );
      return _i8.CityMapRoutePage(
        key: args.key,
        poi: args.poi,
        stack: args.stack,
        locationGateResult: args.locationGateResult,
      );
    },
  );
}

class CityMapRouteArgs {
  const CityMapRouteArgs({
    this.key,
    this.poi,
    this.stack,
    this.locationGateResult,
  });

  final _i75.Key? key;

  final String? poi;

  final String? stack;

  final _i76.LocationPermissionGateResult? locationGateResult;

  @override
  String toString() {
    return 'CityMapRouteArgs{key: $key, poi: $poi, stack: $stack, locationGateResult: $locationGateResult}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CityMapRouteArgs) return false;
    return key == other.key &&
        poi == other.poi &&
        stack == other.stack &&
        locationGateResult == other.locationGateResult;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      poi.hashCode ^
      stack.hashCode ^
      locationGateResult.hashCode;
}

/// generated route for
/// [_i9.ContactGroupManagementRoutePage]
class ContactGroupManagementRoute extends _i74.PageRouteInfo<void> {
  const ContactGroupManagementRoute({List<_i74.PageRouteInfo>? children})
    : super(ContactGroupManagementRoute.name, initialChildren: children);

  static const String name = 'ContactGroupManagementRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      return const _i9.ContactGroupManagementRoutePage();
    },
  );
}

/// generated route for
/// [_i10.DiscoveryRoute]
class DiscoveryRoute extends _i74.PageRouteInfo<void> {
  const DiscoveryRoute({List<_i74.PageRouteInfo>? children})
    : super(DiscoveryRoute.name, initialChildren: children);

  static const String name = 'DiscoveryRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      return const _i10.DiscoveryRoute();
    },
  );
}

/// generated route for
/// [_i11.EventSearchRoute]
class EventSearchRoute extends _i74.PageRouteInfo<EventSearchRouteArgs> {
  EventSearchRoute({
    _i75.Key? key,
    _i77.InviteFilter inviteFilter = _i77.InviteFilter.none,
    bool startWithHistory = false,
    List<_i74.PageRouteInfo>? children,
  }) : super(
         EventSearchRoute.name,
         args: EventSearchRouteArgs(
           key: key,
           inviteFilter: inviteFilter,
           startWithHistory: startWithHistory,
         ),
         initialChildren: children,
       );

  static const String name = 'EventSearchRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<EventSearchRouteArgs>(
        orElse: () => const EventSearchRouteArgs(),
      );
      return _i11.EventSearchRoute(
        key: args.key,
        inviteFilter: args.inviteFilter,
        startWithHistory: args.startWithHistory,
      );
    },
  );
}

class EventSearchRouteArgs {
  const EventSearchRouteArgs({
    this.key,
    this.inviteFilter = _i77.InviteFilter.none,
    this.startWithHistory = false,
  });

  final _i75.Key? key;

  final _i77.InviteFilter inviteFilter;

  final bool startWithHistory;

  @override
  String toString() {
    return 'EventSearchRouteArgs{key: $key, inviteFilter: $inviteFilter, startWithHistory: $startWithHistory}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EventSearchRouteArgs) return false;
    return key == other.key &&
        inviteFilter == other.inviteFilter &&
        startWithHistory == other.startWithHistory;
  }

  @override
  int get hashCode =>
      key.hashCode ^ inviteFilter.hashCode ^ startWithHistory.hashCode;
}

/// generated route for
/// [_i12.ImmersiveEventDetailRoutePage]
class ImmersiveEventDetailRoute
    extends _i74.PageRouteInfo<ImmersiveEventDetailRouteArgs> {
  ImmersiveEventDetailRoute({
    _i75.Key? key,
    required String eventSlug,
    String? occurrenceId,
    String? tab,
    List<_i74.PageRouteInfo>? children,
  }) : super(
         ImmersiveEventDetailRoute.name,
         args: ImmersiveEventDetailRouteArgs(
           key: key,
           eventSlug: eventSlug,
           occurrenceId: occurrenceId,
           tab: tab,
         ),
         rawPathParams: {'slug': eventSlug},
         rawQueryParams: {'occurrence': occurrenceId, 'tab': tab},
         initialChildren: children,
       );

  static const String name = 'ImmersiveEventDetailRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final queryParams = data.queryParams;
      final args = data.argsAs<ImmersiveEventDetailRouteArgs>(
        orElse: () => ImmersiveEventDetailRouteArgs(
          eventSlug: pathParams.getString('slug'),
          occurrenceId: queryParams.optString('occurrence'),
          tab: queryParams.optString('tab'),
        ),
      );
      return _i74.WrappedRoute(
        child: _i12.ImmersiveEventDetailRoutePage(
          key: args.key,
          eventSlug: args.eventSlug,
          occurrenceId: args.occurrenceId,
          tab: args.tab,
        ),
      );
    },
  );
}

class ImmersiveEventDetailRouteArgs {
  const ImmersiveEventDetailRouteArgs({
    this.key,
    required this.eventSlug,
    this.occurrenceId,
    this.tab,
  });

  final _i75.Key? key;

  final String eventSlug;

  final String? occurrenceId;

  final String? tab;

  @override
  String toString() {
    return 'ImmersiveEventDetailRouteArgs{key: $key, eventSlug: $eventSlug, occurrenceId: $occurrenceId, tab: $tab}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ImmersiveEventDetailRouteArgs) return false;
    return key == other.key &&
        eventSlug == other.eventSlug &&
        occurrenceId == other.occurrenceId &&
        tab == other.tab;
  }

  @override
  int get hashCode =>
      key.hashCode ^ eventSlug.hashCode ^ occurrenceId.hashCode ^ tab.hashCode;
}

/// generated route for
/// [_i13.InitRoutePage]
class InitRoute extends _i74.PageRouteInfo<void> {
  const InitRoute({List<_i74.PageRouteInfo>? children})
    : super(InitRoute.name, initialChildren: children);

  static const String name = 'InitRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      return const _i13.InitRoutePage();
    },
  );
}

/// generated route for
/// [_i14.InviteEntryRoutePage]
class InviteEntryRoute extends _i74.PageRouteInfo<void> {
  const InviteEntryRoute({List<_i74.PageRouteInfo>? children})
    : super(InviteEntryRoute.name, initialChildren: children);

  static const String name = 'InviteEntryRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      return const _i14.InviteEntryRoutePage();
    },
  );
}

/// generated route for
/// [_i15.InviteFlowRoutePage]
class InviteFlowRoute extends _i74.PageRouteInfo<void> {
  const InviteFlowRoute({List<_i74.PageRouteInfo>? children})
    : super(InviteFlowRoute.name, initialChildren: children);

  static const String name = 'InviteFlowRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      return const _i15.InviteFlowRoutePage();
    },
  );
}

/// generated route for
/// [_i16.InviteShareRoutePage]
class InviteShareRoute extends _i74.PageRouteInfo<InviteShareRouteArgs> {
  InviteShareRoute({
    _i75.Key? key,
    _i78.InviteModel? invite,
    List<_i74.PageRouteInfo>? children,
  }) : super(
         InviteShareRoute.name,
         args: InviteShareRouteArgs(key: key, invite: invite),
         initialChildren: children,
       );

  static const String name = 'InviteShareRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<InviteShareRouteArgs>(
        orElse: () => const InviteShareRouteArgs(),
      );
      return _i16.InviteShareRoutePage(key: args.key, invite: args.invite);
    },
  );
}

class InviteShareRouteArgs {
  const InviteShareRouteArgs({this.key, this.invite});

  final _i75.Key? key;

  final _i78.InviteModel? invite;

  @override
  String toString() {
    return 'InviteShareRouteArgs{key: $key, invite: $invite}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! InviteShareRouteArgs) return false;
    return key == other.key && invite == other.invite;
  }

  @override
  int get hashCode => key.hashCode ^ invite.hashCode;
}

/// generated route for
/// [_i17.LandlordHomeRoutePage]
class LandlordHomeRoute extends _i74.PageRouteInfo<void> {
  const LandlordHomeRoute({List<_i74.PageRouteInfo>? children})
    : super(LandlordHomeRoute.name, initialChildren: children);

  static const String name = 'LandlordHomeRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      return const _i17.LandlordHomeRoutePage();
    },
  );
}

/// generated route for
/// [_i18.LocationPermissionRoutePage]
class LocationPermissionRoute
    extends _i74.PageRouteInfo<LocationPermissionRouteArgs> {
  LocationPermissionRoute({
    _i75.Key? key,
    _i79.LocationPermissionState? initialState,
    bool allowContinueWithoutLocation = true,
    _i75.ValueChanged<_i76.LocationPermissionGateResult>? onResult,
    bool popRouteAfterResult = false,
    List<_i74.PageRouteInfo>? children,
  }) : super(
         LocationPermissionRoute.name,
         args: LocationPermissionRouteArgs(
           key: key,
           initialState: initialState,
           allowContinueWithoutLocation: allowContinueWithoutLocation,
           onResult: onResult,
           popRouteAfterResult: popRouteAfterResult,
         ),
         initialChildren: children,
       );

  static const String name = 'LocationPermissionRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<LocationPermissionRouteArgs>(
        orElse: () => const LocationPermissionRouteArgs(),
      );
      return _i18.LocationPermissionRoutePage(
        key: args.key,
        initialState: args.initialState,
        allowContinueWithoutLocation: args.allowContinueWithoutLocation,
        onResult: args.onResult,
        popRouteAfterResult: args.popRouteAfterResult,
      );
    },
  );
}

class LocationPermissionRouteArgs {
  const LocationPermissionRouteArgs({
    this.key,
    this.initialState,
    this.allowContinueWithoutLocation = true,
    this.onResult,
    this.popRouteAfterResult = false,
  });

  final _i75.Key? key;

  final _i79.LocationPermissionState? initialState;

  final bool allowContinueWithoutLocation;

  final _i75.ValueChanged<_i76.LocationPermissionGateResult>? onResult;

  final bool popRouteAfterResult;

  @override
  String toString() {
    return 'LocationPermissionRouteArgs{key: $key, initialState: $initialState, allowContinueWithoutLocation: $allowContinueWithoutLocation, onResult: $onResult, popRouteAfterResult: $popRouteAfterResult}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LocationPermissionRouteArgs) return false;
    return key == other.key &&
        initialState == other.initialState &&
        allowContinueWithoutLocation == other.allowContinueWithoutLocation &&
        onResult == other.onResult &&
        popRouteAfterResult == other.popRouteAfterResult;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      initialState.hashCode ^
      allowContinueWithoutLocation.hashCode ^
      onResult.hashCode ^
      popRouteAfterResult.hashCode;
}

/// generated route for
/// [_i19.PartnerDetailRoute]
class PartnerDetailRoute extends _i74.PageRouteInfo<PartnerDetailRouteArgs> {
  PartnerDetailRoute({
    _i75.Key? key,
    required String slug,
    List<_i74.PageRouteInfo>? children,
  }) : super(
         PartnerDetailRoute.name,
         args: PartnerDetailRouteArgs(key: key, slug: slug),
         rawPathParams: {'slug': slug},
         initialChildren: children,
       );

  static const String name = 'PartnerDetailRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<PartnerDetailRouteArgs>(
        orElse: () =>
            PartnerDetailRouteArgs(slug: pathParams.getString('slug')),
      );
      return _i74.WrappedRoute(
        child: _i19.PartnerDetailRoute(key: args.key, slug: args.slug),
      );
    },
  );
}

class PartnerDetailRouteArgs {
  const PartnerDetailRouteArgs({this.key, required this.slug});

  final _i75.Key? key;

  final String slug;

  @override
  String toString() {
    return 'PartnerDetailRouteArgs{key: $key, slug: $slug}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PartnerDetailRouteArgs) return false;
    return key == other.key && slug == other.slug;
  }

  @override
  int get hashCode => key.hashCode ^ slug.hashCode;
}

/// generated route for
/// [_i20.PoiDetailsRoutePage]
class PoiDetailsRoute extends _i74.PageRouteInfo<PoiDetailsRouteArgs> {
  PoiDetailsRoute({
    _i75.Key? key,
    String? poi,
    String? stack,
    _i76.LocationPermissionGateResult? locationGateResult,
    List<_i74.PageRouteInfo>? children,
  }) : super(
         PoiDetailsRoute.name,
         args: PoiDetailsRouteArgs(
           key: key,
           poi: poi,
           stack: stack,
           locationGateResult: locationGateResult,
         ),
         rawQueryParams: {'poi': poi, 'stack': stack},
         initialChildren: children,
       );

  static const String name = 'PoiDetailsRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      final queryParams = data.queryParams;
      final args = data.argsAs<PoiDetailsRouteArgs>(
        orElse: () => PoiDetailsRouteArgs(
          poi: queryParams.optString('poi'),
          stack: queryParams.optString('stack'),
        ),
      );
      return _i20.PoiDetailsRoutePage(
        key: args.key,
        poi: args.poi,
        stack: args.stack,
        locationGateResult: args.locationGateResult,
      );
    },
  );
}

class PoiDetailsRouteArgs {
  const PoiDetailsRouteArgs({
    this.key,
    this.poi,
    this.stack,
    this.locationGateResult,
  });

  final _i75.Key? key;

  final String? poi;

  final String? stack;

  final _i76.LocationPermissionGateResult? locationGateResult;

  @override
  String toString() {
    return 'PoiDetailsRouteArgs{key: $key, poi: $poi, stack: $stack, locationGateResult: $locationGateResult}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PoiDetailsRouteArgs) return false;
    return key == other.key &&
        poi == other.poi &&
        stack == other.stack &&
        locationGateResult == other.locationGateResult;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      poi.hashCode ^
      stack.hashCode ^
      locationGateResult.hashCode;
}

/// generated route for
/// [_i21.ProfileRoutePage]
class ProfileRoute extends _i74.PageRouteInfo<void> {
  const ProfileRoute({List<_i74.PageRouteInfo>? children})
    : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      return const _i21.ProfileRoutePage();
    },
  );
}

/// generated route for
/// [_i22.RecoveryPasswordRoutePage]
class RecoveryPasswordRoute
    extends _i74.PageRouteInfo<RecoveryPasswordRouteArgs> {
  RecoveryPasswordRoute({
    _i75.Key? key,
    String? initialEmmail,
    List<_i74.PageRouteInfo>? children,
  }) : super(
         RecoveryPasswordRoute.name,
         args: RecoveryPasswordRouteArgs(
           key: key,
           initialEmmail: initialEmmail,
         ),
         initialChildren: children,
       );

  static const String name = 'RecoveryPasswordRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RecoveryPasswordRouteArgs>(
        orElse: () => const RecoveryPasswordRouteArgs(),
      );
      return _i22.RecoveryPasswordRoutePage(
        key: args.key,
        initialEmmail: args.initialEmmail,
      );
    },
  );
}

class RecoveryPasswordRouteArgs {
  const RecoveryPasswordRouteArgs({this.key, this.initialEmmail});

  final _i75.Key? key;

  final String? initialEmmail;

  @override
  String toString() {
    return 'RecoveryPasswordRouteArgs{key: $key, initialEmmail: $initialEmmail}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RecoveryPasswordRouteArgs) return false;
    return key == other.key && initialEmmail == other.initialEmmail;
  }

  @override
  int get hashCode => key.hashCode ^ initialEmmail.hashCode;
}

/// generated route for
/// [_i23.StaticAssetDetailRoute]
class StaticAssetDetailRoute
    extends _i74.PageRouteInfo<StaticAssetDetailRouteArgs> {
  StaticAssetDetailRoute({
    _i75.Key? key,
    required String assetRef,
    List<_i74.PageRouteInfo>? children,
  }) : super(
         StaticAssetDetailRoute.name,
         args: StaticAssetDetailRouteArgs(key: key, assetRef: assetRef),
         rawPathParams: {'assetRef': assetRef},
         initialChildren: children,
       );

  static const String name = 'StaticAssetDetailRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<StaticAssetDetailRouteArgs>(
        orElse: () => StaticAssetDetailRouteArgs(
          assetRef: pathParams.getString('assetRef'),
        ),
      );
      return _i74.WrappedRoute(
        child: _i23.StaticAssetDetailRoute(
          key: args.key,
          assetRef: args.assetRef,
        ),
      );
    },
  );
}

class StaticAssetDetailRouteArgs {
  const StaticAssetDetailRouteArgs({this.key, required this.assetRef});

  final _i75.Key? key;

  final String assetRef;

  @override
  String toString() {
    return 'StaticAssetDetailRouteArgs{key: $key, assetRef: $assetRef}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StaticAssetDetailRouteArgs) return false;
    return key == other.key && assetRef == other.assetRef;
  }

  @override
  int get hashCode => key.hashCode ^ assetRef.hashCode;
}

/// generated route for
/// [_i24.TenantAdminAccountCreateRoutePage]
class TenantAdminAccountCreateRoute extends _i74.PageRouteInfo<void> {
  const TenantAdminAccountCreateRoute({List<_i74.PageRouteInfo>? children})
    : super(TenantAdminAccountCreateRoute.name, initialChildren: children);

  static const String name = 'TenantAdminAccountCreateRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      return const _i24.TenantAdminAccountCreateRoutePage();
    },
  );
}

/// generated route for
/// [_i25.TenantAdminAccountDetailRoutePage]
class TenantAdminAccountDetailRoute
    extends _i74.PageRouteInfo<TenantAdminAccountDetailRouteArgs> {
  TenantAdminAccountDetailRoute({
    _i75.Key? key,
    required String accountSlug,
    List<_i74.PageRouteInfo>? children,
  }) : super(
         TenantAdminAccountDetailRoute.name,
         args: TenantAdminAccountDetailRouteArgs(
           key: key,
           accountSlug: accountSlug,
         ),
         rawPathParams: {'accountSlug': accountSlug},
         initialChildren: children,
       );

  static const String name = 'TenantAdminAccountDetailRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminAccountDetailRouteArgs>(
        orElse: () => TenantAdminAccountDetailRouteArgs(
          accountSlug: pathParams.getString('accountSlug'),
        ),
      );
      return _i25.TenantAdminAccountDetailRoutePage(
        key: args.key,
        accountSlug: args.accountSlug,
      );
    },
  );
}

class TenantAdminAccountDetailRouteArgs {
  const TenantAdminAccountDetailRouteArgs({
    this.key,
    required this.accountSlug,
  });

  final _i75.Key? key;

  final String accountSlug;

  @override
  String toString() {
    return 'TenantAdminAccountDetailRouteArgs{key: $key, accountSlug: $accountSlug}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TenantAdminAccountDetailRouteArgs) return false;
    return key == other.key && accountSlug == other.accountSlug;
  }

  @override
  int get hashCode => key.hashCode ^ accountSlug.hashCode;
}

/// generated route for
/// [_i26.TenantAdminAccountProfileCreateRoutePage]
class TenantAdminAccountProfileCreateRoute
    extends _i74.PageRouteInfo<TenantAdminAccountProfileCreateRouteArgs> {
  TenantAdminAccountProfileCreateRoute({
    _i75.Key? key,
    required String accountSlug,
    List<_i74.PageRouteInfo>? children,
  }) : super(
         TenantAdminAccountProfileCreateRoute.name,
         args: TenantAdminAccountProfileCreateRouteArgs(
           key: key,
           accountSlug: accountSlug,
         ),
         rawPathParams: {'accountSlug': accountSlug},
         initialChildren: children,
       );

  static const String name = 'TenantAdminAccountProfileCreateRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminAccountProfileCreateRouteArgs>(
        orElse: () => TenantAdminAccountProfileCreateRouteArgs(
          accountSlug: pathParams.getString('accountSlug'),
        ),
      );
      return _i26.TenantAdminAccountProfileCreateRoutePage(
        key: args.key,
        accountSlug: args.accountSlug,
      );
    },
  );
}

class TenantAdminAccountProfileCreateRouteArgs {
  const TenantAdminAccountProfileCreateRouteArgs({
    this.key,
    required this.accountSlug,
  });

  final _i75.Key? key;

  final String accountSlug;

  @override
  String toString() {
    return 'TenantAdminAccountProfileCreateRouteArgs{key: $key, accountSlug: $accountSlug}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TenantAdminAccountProfileCreateRouteArgs) return false;
    return key == other.key && accountSlug == other.accountSlug;
  }

  @override
  int get hashCode => key.hashCode ^ accountSlug.hashCode;
}

/// generated route for
/// [_i27.TenantAdminAccountProfileEditRoutePage]
class TenantAdminAccountProfileEditRoute
    extends _i74.PageRouteInfo<TenantAdminAccountProfileEditRouteArgs> {
  TenantAdminAccountProfileEditRoute({
    _i75.Key? key,
    required String accountSlug,
    required String accountProfileId,
    List<_i74.PageRouteInfo>? children,
  }) : super(
         TenantAdminAccountProfileEditRoute.name,
         args: TenantAdminAccountProfileEditRouteArgs(
           key: key,
           accountSlug: accountSlug,
           accountProfileId: accountProfileId,
         ),
         rawPathParams: {
           'accountSlug': accountSlug,
           'accountProfileId': accountProfileId,
         },
         initialChildren: children,
       );

  static const String name = 'TenantAdminAccountProfileEditRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminAccountProfileEditRouteArgs>(
        orElse: () => TenantAdminAccountProfileEditRouteArgs(
          accountSlug: pathParams.getString('accountSlug'),
          accountProfileId: pathParams.getString('accountProfileId'),
        ),
      );
      return _i27.TenantAdminAccountProfileEditRoutePage(
        key: args.key,
        accountSlug: args.accountSlug,
        accountProfileId: args.accountProfileId,
      );
    },
  );
}

class TenantAdminAccountProfileEditRouteArgs {
  const TenantAdminAccountProfileEditRouteArgs({
    this.key,
    required this.accountSlug,
    required this.accountProfileId,
  });

  final _i75.Key? key;

  final String accountSlug;

  final String accountProfileId;

  @override
  String toString() {
    return 'TenantAdminAccountProfileEditRouteArgs{key: $key, accountSlug: $accountSlug, accountProfileId: $accountProfileId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TenantAdminAccountProfileEditRouteArgs) return false;
    return key == other.key &&
        accountSlug == other.accountSlug &&
        accountProfileId == other.accountProfileId;
  }

  @override
  int get hashCode =>
      key.hashCode ^ accountSlug.hashCode ^ accountProfileId.hashCode;
}

/// generated route for
/// [_i28.TenantAdminAccountProfileExternalLinkAddRoutePage]
class TenantAdminAccountProfileExternalLinkAddRoute
    extends
        _i74.PageRouteInfo<TenantAdminAccountProfileExternalLinkAddRouteArgs> {
  TenantAdminAccountProfileExternalLinkAddRoute({
    _i75.Key? key,
    required String accountSlug,
    required String accountProfileId,
    List<_i74.PageRouteInfo>? children,
  }) : super(
         TenantAdminAccountProfileExternalLinkAddRoute.name,
         args: TenantAdminAccountProfileExternalLinkAddRouteArgs(
           key: key,
           accountSlug: accountSlug,
           accountProfileId: accountProfileId,
         ),
         rawPathParams: {
           'accountSlug': accountSlug,
           'accountProfileId': accountProfileId,
         },
         initialChildren: children,
       );

  static const String name = 'TenantAdminAccountProfileExternalLinkAddRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data
          .argsAs<TenantAdminAccountProfileExternalLinkAddRouteArgs>(
            orElse: () => TenantAdminAccountProfileExternalLinkAddRouteArgs(
              accountSlug: pathParams.getString('accountSlug'),
              accountProfileId: pathParams.getString('accountProfileId'),
            ),
          );
      return _i28.TenantAdminAccountProfileExternalLinkAddRoutePage(
        key: args.key,
        accountSlug: args.accountSlug,
        accountProfileId: args.accountProfileId,
      );
    },
  );
}

class TenantAdminAccountProfileExternalLinkAddRouteArgs {
  const TenantAdminAccountProfileExternalLinkAddRouteArgs({
    this.key,
    required this.accountSlug,
    required this.accountProfileId,
  });

  final _i75.Key? key;

  final String accountSlug;

  final String accountProfileId;

  @override
  String toString() {
    return 'TenantAdminAccountProfileExternalLinkAddRouteArgs{key: $key, accountSlug: $accountSlug, accountProfileId: $accountProfileId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TenantAdminAccountProfileExternalLinkAddRouteArgs)
      return false;
    return key == other.key &&
        accountSlug == other.accountSlug &&
        accountProfileId == other.accountProfileId;
  }

  @override
  int get hashCode =>
      key.hashCode ^ accountSlug.hashCode ^ accountProfileId.hashCode;
}

/// generated route for
/// [_i29.TenantAdminAccountProfileExternalLinkEditRoutePage]
class TenantAdminAccountProfileExternalLinkEditRoute
    extends
        _i74.PageRouteInfo<TenantAdminAccountProfileExternalLinkEditRouteArgs> {
  TenantAdminAccountProfileExternalLinkEditRoute({
    _i75.Key? key,
    required String accountSlug,
    required String accountProfileId,
    required String externalLinkId,
    List<_i74.PageRouteInfo>? children,
  }) : super(
         TenantAdminAccountProfileExternalLinkEditRoute.name,
         args: TenantAdminAccountProfileExternalLinkEditRouteArgs(
           key: key,
           accountSlug: accountSlug,
           accountProfileId: accountProfileId,
           externalLinkId: externalLinkId,
         ),
         rawPathParams: {
           'accountSlug': accountSlug,
           'accountProfileId': accountProfileId,
           'externalLinkId': externalLinkId,
         },
         initialChildren: children,
       );

  static const String name = 'TenantAdminAccountProfileExternalLinkEditRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data
          .argsAs<TenantAdminAccountProfileExternalLinkEditRouteArgs>(
            orElse: () => TenantAdminAccountProfileExternalLinkEditRouteArgs(
              accountSlug: pathParams.getString('accountSlug'),
              accountProfileId: pathParams.getString('accountProfileId'),
              externalLinkId: pathParams.getString('externalLinkId'),
            ),
          );
      return _i29.TenantAdminAccountProfileExternalLinkEditRoutePage(
        key: args.key,
        accountSlug: args.accountSlug,
        accountProfileId: args.accountProfileId,
        externalLinkId: args.externalLinkId,
      );
    },
  );
}

class TenantAdminAccountProfileExternalLinkEditRouteArgs {
  const TenantAdminAccountProfileExternalLinkEditRouteArgs({
    this.key,
    required this.accountSlug,
    required this.accountProfileId,
    required this.externalLinkId,
  });

  final _i75.Key? key;

  final String accountSlug;

  final String accountProfileId;

  final String externalLinkId;

  @override
  String toString() {
    return 'TenantAdminAccountProfileExternalLinkEditRouteArgs{key: $key, accountSlug: $accountSlug, accountProfileId: $accountProfileId, externalLinkId: $externalLinkId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TenantAdminAccountProfileExternalLinkEditRouteArgs)
      return false;
    return key == other.key &&
        accountSlug == other.accountSlug &&
        accountProfileId == other.accountProfileId &&
        externalLinkId == other.externalLinkId;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      accountSlug.hashCode ^
      accountProfileId.hashCode ^
      externalLinkId.hashCode;
}

/// generated route for
/// [_i30.TenantAdminAccountProfileGroupMembersRoutePage]
class TenantAdminAccountProfileGroupMembersRoute
    extends _i74.PageRouteInfo<TenantAdminAccountProfileGroupMembersRouteArgs> {
  TenantAdminAccountProfileGroupMembersRoute({
    _i75.Key? key,
    required String accountSlug,
    required String accountProfileId,
    required String groupId,
    List<_i74.PageRouteInfo>? children,
  }) : super(
         TenantAdminAccountProfileGroupMembersRoute.name,
         args: TenantAdminAccountProfileGroupMembersRouteArgs(
           key: key,
           accountSlug: accountSlug,
           accountProfileId: accountProfileId,
           groupId: groupId,
         ),
         rawPathParams: {
           'accountSlug': accountSlug,
           'accountProfileId': accountProfileId,
           'groupId': groupId,
         },
         initialChildren: children,
       );

  static const String name = 'TenantAdminAccountProfileGroupMembersRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminAccountProfileGroupMembersRouteArgs>(
        orElse: () => TenantAdminAccountProfileGroupMembersRouteArgs(
          accountSlug: pathParams.getString('accountSlug'),
          accountProfileId: pathParams.getString('accountProfileId'),
          groupId: pathParams.getString('groupId'),
        ),
      );
      return _i30.TenantAdminAccountProfileGroupMembersRoutePage(
        key: args.key,
        accountSlug: args.accountSlug,
        accountProfileId: args.accountProfileId,
        groupId: args.groupId,
      );
    },
  );
}

class TenantAdminAccountProfileGroupMembersRouteArgs {
  const TenantAdminAccountProfileGroupMembersRouteArgs({
    this.key,
    required this.accountSlug,
    required this.accountProfileId,
    required this.groupId,
  });

  final _i75.Key? key;

  final String accountSlug;

  final String accountProfileId;

  final String groupId;

  @override
  String toString() {
    return 'TenantAdminAccountProfileGroupMembersRouteArgs{key: $key, accountSlug: $accountSlug, accountProfileId: $accountProfileId, groupId: $groupId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TenantAdminAccountProfileGroupMembersRouteArgs) return false;
    return key == other.key &&
        accountSlug == other.accountSlug &&
        accountProfileId == other.accountProfileId &&
        groupId == other.groupId;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      accountSlug.hashCode ^
      accountProfileId.hashCode ^
      groupId.hashCode;
}

/// generated route for
/// [_i31.TenantAdminAccountsListRoutePage]
class TenantAdminAccountsListRoute extends _i74.PageRouteInfo<void> {
  const TenantAdminAccountsListRoute({List<_i74.PageRouteInfo>? children})
    : super(TenantAdminAccountsListRoute.name, initialChildren: children);

  static const String name = 'TenantAdminAccountsListRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      return const _i31.TenantAdminAccountsListRoutePage();
    },
  );
}

/// generated route for
/// [_i32.TenantAdminDashboardRoutePage]
class TenantAdminDashboardRoute extends _i74.PageRouteInfo<void> {
  const TenantAdminDashboardRoute({List<_i74.PageRouteInfo>? children})
    : super(TenantAdminDashboardRoute.name, initialChildren: children);

  static const String name = 'TenantAdminDashboardRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      return const _i32.TenantAdminDashboardRoutePage();
    },
  );
}

/// generated route for
/// [_i33.TenantAdminDiscoveryFilterSurfaceRoutePage]
class TenantAdminDiscoveryFilterSurfaceRoute
    extends _i74.PageRouteInfo<TenantAdminDiscoveryFilterSurfaceRouteArgs> {
  TenantAdminDiscoveryFilterSurfaceRoute({
    _i75.Key? key,
    String? surfaceKey,
    List<_i74.PageRouteInfo>? children,
  }) : super(
         TenantAdminDiscoveryFilterSurfaceRoute.name,
         args: TenantAdminDiscoveryFilterSurfaceRouteArgs(
           key: key,
           surfaceKey: surfaceKey,
         ),
         rawQueryParams: {'surface': surfaceKey},
         initialChildren: children,
       );

  static const String name = 'TenantAdminDiscoveryFilterSurfaceRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      final queryParams = data.queryParams;
      final args = data.argsAs<TenantAdminDiscoveryFilterSurfaceRouteArgs>(
        orElse: () => TenantAdminDiscoveryFilterSurfaceRouteArgs(
          surfaceKey: queryParams.optString('surface'),
        ),
      );
      return _i33.TenantAdminDiscoveryFilterSurfaceRoutePage(
        key: args.key,
        surfaceKey: args.surfaceKey,
      );
    },
  );
}

class TenantAdminDiscoveryFilterSurfaceRouteArgs {
  const TenantAdminDiscoveryFilterSurfaceRouteArgs({this.key, this.surfaceKey});

  final _i75.Key? key;

  final String? surfaceKey;

  @override
  String toString() {
    return 'TenantAdminDiscoveryFilterSurfaceRouteArgs{key: $key, surfaceKey: $surfaceKey}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TenantAdminDiscoveryFilterSurfaceRouteArgs) return false;
    return key == other.key && surfaceKey == other.surfaceKey;
  }

  @override
  int get hashCode => key.hashCode ^ surfaceKey.hashCode;
}

/// generated route for
/// [_i34.TenantAdminDiscoveryFiltersRoutePage]
class TenantAdminDiscoveryFiltersRoute extends _i74.PageRouteInfo<void> {
  const TenantAdminDiscoveryFiltersRoute({List<_i74.PageRouteInfo>? children})
    : super(TenantAdminDiscoveryFiltersRoute.name, initialChildren: children);

  static const String name = 'TenantAdminDiscoveryFiltersRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      return const _i34.TenantAdminDiscoveryFiltersRoutePage();
    },
  );
}

/// generated route for
/// [_i35.TenantAdminEventCreateRoutePage]
class TenantAdminEventCreateRoute extends _i74.PageRouteInfo<void> {
  const TenantAdminEventCreateRoute({List<_i74.PageRouteInfo>? children})
    : super(TenantAdminEventCreateRoute.name, initialChildren: children);

  static const String name = 'TenantAdminEventCreateRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      return const _i35.TenantAdminEventCreateRoutePage();
    },
  );
}

/// generated route for
/// [_i36.TenantAdminEventEditRoutePage]
class TenantAdminEventEditRoute
    extends _i74.PageRouteInfo<TenantAdminEventEditRouteArgs> {
  TenantAdminEventEditRoute({
    _i75.Key? key,
    required String eventId,
    String? occurrenceId,
    List<_i74.PageRouteInfo>? children,
  }) : super(
         TenantAdminEventEditRoute.name,
         args: TenantAdminEventEditRouteArgs(
           key: key,
           eventId: eventId,
           occurrenceId: occurrenceId,
         ),
         rawPathParams: {'eventId': eventId},
         rawQueryParams: {'occurrence': occurrenceId},
         initialChildren: children,
       );

  static const String name = 'TenantAdminEventEditRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final queryParams = data.queryParams;
      final args = data.argsAs<TenantAdminEventEditRouteArgs>(
        orElse: () => TenantAdminEventEditRouteArgs(
          eventId: pathParams.getString('eventId'),
          occurrenceId: queryParams.optString('occurrence'),
        ),
      );
      return _i74.WrappedRoute(
        child: _i36.TenantAdminEventEditRoutePage(
          key: args.key,
          eventId: args.eventId,
          occurrenceId: args.occurrenceId,
        ),
      );
    },
  );
}

class TenantAdminEventEditRouteArgs {
  const TenantAdminEventEditRouteArgs({
    this.key,
    required this.eventId,
    this.occurrenceId,
  });

  final _i75.Key? key;

  final String eventId;

  final String? occurrenceId;

  @override
  String toString() {
    return 'TenantAdminEventEditRouteArgs{key: $key, eventId: $eventId, occurrenceId: $occurrenceId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TenantAdminEventEditRouteArgs) return false;
    return key == other.key &&
        eventId == other.eventId &&
        occurrenceId == other.occurrenceId;
  }

  @override
  int get hashCode => key.hashCode ^ eventId.hashCode ^ occurrenceId.hashCode;
}

/// generated route for
/// [_i37.TenantAdminEventOccurrenceGroupMembersRoutePage]
class TenantAdminEventOccurrenceGroupMembersRoute
    extends
        _i74.PageRouteInfo<TenantAdminEventOccurrenceGroupMembersRouteArgs> {
  TenantAdminEventOccurrenceGroupMembersRoute({
    _i75.Key? key,
    required String eventId,
    required String occurrenceId,
    required String occurrenceKey,
    required String groupId,
    List<_i74.PageRouteInfo>? children,
  }) : super(
         TenantAdminEventOccurrenceGroupMembersRoute.name,
         args: TenantAdminEventOccurrenceGroupMembersRouteArgs(
           key: key,
           eventId: eventId,
           occurrenceId: occurrenceId,
           occurrenceKey: occurrenceKey,
           groupId: groupId,
         ),
         rawPathParams: {
           'eventId': eventId,
           'occurrenceId': occurrenceId,
           'occurrenceKey': occurrenceKey,
           'groupId': groupId,
         },
         initialChildren: children,
       );

  static const String name = 'TenantAdminEventOccurrenceGroupMembersRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminEventOccurrenceGroupMembersRouteArgs>(
        orElse: () => TenantAdminEventOccurrenceGroupMembersRouteArgs(
          eventId: pathParams.getString('eventId'),
          occurrenceId: pathParams.getString('occurrenceId'),
          occurrenceKey: pathParams.getString('occurrenceKey'),
          groupId: pathParams.getString('groupId'),
        ),
      );
      return _i74.WrappedRoute(
        child: _i37.TenantAdminEventOccurrenceGroupMembersRoutePage(
          key: args.key,
          eventId: args.eventId,
          occurrenceId: args.occurrenceId,
          occurrenceKey: args.occurrenceKey,
          groupId: args.groupId,
        ),
      );
    },
  );
}

class TenantAdminEventOccurrenceGroupMembersRouteArgs {
  const TenantAdminEventOccurrenceGroupMembersRouteArgs({
    this.key,
    required this.eventId,
    required this.occurrenceId,
    required this.occurrenceKey,
    required this.groupId,
  });

  final _i75.Key? key;

  final String eventId;

  final String occurrenceId;

  final String occurrenceKey;

  final String groupId;

  @override
  String toString() {
    return 'TenantAdminEventOccurrenceGroupMembersRouteArgs{key: $key, eventId: $eventId, occurrenceId: $occurrenceId, occurrenceKey: $occurrenceKey, groupId: $groupId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TenantAdminEventOccurrenceGroupMembersRouteArgs) return false;
    return key == other.key &&
        eventId == other.eventId &&
        occurrenceId == other.occurrenceId &&
        occurrenceKey == other.occurrenceKey &&
        groupId == other.groupId;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      eventId.hashCode ^
      occurrenceId.hashCode ^
      occurrenceKey.hashCode ^
      groupId.hashCode;
}

/// generated route for
/// [_i38.TenantAdminEventTypeCreateRoutePage]
class TenantAdminEventTypeCreateRoute extends _i74.PageRouteInfo<void> {
  const TenantAdminEventTypeCreateRoute({List<_i74.PageRouteInfo>? children})
    : super(TenantAdminEventTypeCreateRoute.name, initialChildren: children);

  static const String name = 'TenantAdminEventTypeCreateRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      return const _i38.TenantAdminEventTypeCreateRoutePage();
    },
  );
}

/// generated route for
/// [_i39.TenantAdminEventTypeEditRoutePage]
class TenantAdminEventTypeEditRoute
    extends _i74.PageRouteInfo<TenantAdminEventTypeEditRouteArgs> {
  TenantAdminEventTypeEditRoute({
    _i80.TenantAdminEventType? type,
    _i75.Key? key,
    List<_i74.PageRouteInfo>? children,
  }) : super(
         TenantAdminEventTypeEditRoute.name,
         args: TenantAdminEventTypeEditRouteArgs(type: type, key: key),
         initialChildren: children,
       );

  static const String name = 'TenantAdminEventTypeEditRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TenantAdminEventTypeEditRouteArgs>(
        orElse: () => const TenantAdminEventTypeEditRouteArgs(),
      );
      return _i39.TenantAdminEventTypeEditRoutePage(
        type: args.type,
        key: args.key,
      );
    },
  );
}

class TenantAdminEventTypeEditRouteArgs {
  const TenantAdminEventTypeEditRouteArgs({this.type, this.key});

  final _i80.TenantAdminEventType? type;

  final _i75.Key? key;

  @override
  String toString() {
    return 'TenantAdminEventTypeEditRouteArgs{type: $type, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TenantAdminEventTypeEditRouteArgs) return false;
    return type == other.type && key == other.key;
  }

  @override
  int get hashCode => type.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i40.TenantAdminEventTypesRoutePage]
class TenantAdminEventTypesRoute extends _i74.PageRouteInfo<void> {
  const TenantAdminEventTypesRoute({List<_i74.PageRouteInfo>? children})
    : super(TenantAdminEventTypesRoute.name, initialChildren: children);

  static const String name = 'TenantAdminEventTypesRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      return const _i40.TenantAdminEventTypesRoutePage();
    },
  );
}

/// generated route for
/// [_i41.TenantAdminEventsRoutePage]
class TenantAdminEventsRoute extends _i74.PageRouteInfo<void> {
  const TenantAdminEventsRoute({List<_i74.PageRouteInfo>? children})
    : super(TenantAdminEventsRoute.name, initialChildren: children);

  static const String name = 'TenantAdminEventsRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      return const _i41.TenantAdminEventsRoutePage();
    },
  );
}

/// generated route for
/// [_i42.TenantAdminLocationPickerRoutePage]
class TenantAdminLocationPickerRoute
    extends _i74.PageRouteInfo<TenantAdminLocationPickerRouteArgs> {
  TenantAdminLocationPickerRoute({
    _i75.Key? key,
    _i81.TenantAdminLocation? initialLocation,
    _i74.PageRouteInfo<dynamic>? backFallbackRoute,
    List<_i74.PageRouteInfo>? children,
  }) : super(
         TenantAdminLocationPickerRoute.name,
         args: TenantAdminLocationPickerRouteArgs(
           key: key,
           initialLocation: initialLocation,
           backFallbackRoute: backFallbackRoute,
         ),
         initialChildren: children,
       );

  static const String name = 'TenantAdminLocationPickerRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TenantAdminLocationPickerRouteArgs>(
        orElse: () => const TenantAdminLocationPickerRouteArgs(),
      );
      return _i42.TenantAdminLocationPickerRoutePage(
        key: args.key,
        initialLocation: args.initialLocation,
        backFallbackRoute: args.backFallbackRoute,
      );
    },
  );
}

class TenantAdminLocationPickerRouteArgs {
  const TenantAdminLocationPickerRouteArgs({
    this.key,
    this.initialLocation,
    this.backFallbackRoute,
  });

  final _i75.Key? key;

  final _i81.TenantAdminLocation? initialLocation;

  final _i74.PageRouteInfo<dynamic>? backFallbackRoute;

  @override
  String toString() {
    return 'TenantAdminLocationPickerRouteArgs{key: $key, initialLocation: $initialLocation, backFallbackRoute: $backFallbackRoute}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TenantAdminLocationPickerRouteArgs) return false;
    return key == other.key &&
        initialLocation == other.initialLocation &&
        backFallbackRoute == other.backFallbackRoute;
  }

  @override
  int get hashCode =>
      key.hashCode ^ initialLocation.hashCode ^ backFallbackRoute.hashCode;
}

/// generated route for
/// [_i43.TenantAdminOrganizationCreateRoutePage]
class TenantAdminOrganizationCreateRoute extends _i74.PageRouteInfo<void> {
  const TenantAdminOrganizationCreateRoute({List<_i74.PageRouteInfo>? children})
    : super(TenantAdminOrganizationCreateRoute.name, initialChildren: children);

  static const String name = 'TenantAdminOrganizationCreateRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      return const _i43.TenantAdminOrganizationCreateRoutePage();
    },
  );
}

/// generated route for
/// [_i44.TenantAdminOrganizationDetailRoutePage]
class TenantAdminOrganizationDetailRoute
    extends _i74.PageRouteInfo<TenantAdminOrganizationDetailRouteArgs> {
  TenantAdminOrganizationDetailRoute({
    _i75.Key? key,
    required String organizationId,
    List<_i74.PageRouteInfo>? children,
  }) : super(
         TenantAdminOrganizationDetailRoute.name,
         args: TenantAdminOrganizationDetailRouteArgs(
           key: key,
           organizationId: organizationId,
         ),
         rawPathParams: {'organizationId': organizationId},
         initialChildren: children,
       );

  static const String name = 'TenantAdminOrganizationDetailRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminOrganizationDetailRouteArgs>(
        orElse: () => TenantAdminOrganizationDetailRouteArgs(
          organizationId: pathParams.getString('organizationId'),
        ),
      );
      return _i44.TenantAdminOrganizationDetailRoutePage(
        key: args.key,
        organizationId: args.organizationId,
      );
    },
  );
}

class TenantAdminOrganizationDetailRouteArgs {
  const TenantAdminOrganizationDetailRouteArgs({
    this.key,
    required this.organizationId,
  });

  final _i75.Key? key;

  final String organizationId;

  @override
  String toString() {
    return 'TenantAdminOrganizationDetailRouteArgs{key: $key, organizationId: $organizationId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TenantAdminOrganizationDetailRouteArgs) return false;
    return key == other.key && organizationId == other.organizationId;
  }

  @override
  int get hashCode => key.hashCode ^ organizationId.hashCode;
}

/// generated route for
/// [_i45.TenantAdminOrganizationsListRoutePage]
class TenantAdminOrganizationsListRoute extends _i74.PageRouteInfo<void> {
  const TenantAdminOrganizationsListRoute({List<_i74.PageRouteInfo>? children})
    : super(TenantAdminOrganizationsListRoute.name, initialChildren: children);

  static const String name = 'TenantAdminOrganizationsListRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      return const _i45.TenantAdminOrganizationsListRoutePage();
    },
  );
}

/// generated route for
/// [_i46.TenantAdminProfileTypeCreateRoutePage]
class TenantAdminProfileTypeCreateRoute extends _i74.PageRouteInfo<void> {
  const TenantAdminProfileTypeCreateRoute({List<_i74.PageRouteInfo>? children})
    : super(TenantAdminProfileTypeCreateRoute.name, initialChildren: children);

  static const String name = 'TenantAdminProfileTypeCreateRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      return const _i46.TenantAdminProfileTypeCreateRoutePage();
    },
  );
}

/// generated route for
/// [_i47.TenantAdminProfileTypeDetailRoutePage]
class TenantAdminProfileTypeDetailRoute
    extends _i74.PageRouteInfo<TenantAdminProfileTypeDetailRouteArgs> {
  TenantAdminProfileTypeDetailRoute({
    _i75.Key? key,
    required String profileType,
    List<_i74.PageRouteInfo>? children,
  }) : super(
         TenantAdminProfileTypeDetailRoute.name,
         args: TenantAdminProfileTypeDetailRouteArgs(
           key: key,
           profileType: profileType,
         ),
         rawPathParams: {'profileType': profileType},
         initialChildren: children,
       );

  static const String name = 'TenantAdminProfileTypeDetailRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminProfileTypeDetailRouteArgs>(
        orElse: () => TenantAdminProfileTypeDetailRouteArgs(
          profileType: pathParams.getString('profileType'),
        ),
      );
      return _i47.TenantAdminProfileTypeDetailRoutePage(
        key: args.key,
        profileType: args.profileType,
      );
    },
  );
}

class TenantAdminProfileTypeDetailRouteArgs {
  const TenantAdminProfileTypeDetailRouteArgs({
    this.key,
    required this.profileType,
  });

  final _i75.Key? key;

  final String profileType;

  @override
  String toString() {
    return 'TenantAdminProfileTypeDetailRouteArgs{key: $key, profileType: $profileType}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TenantAdminProfileTypeDetailRouteArgs) return false;
    return key == other.key && profileType == other.profileType;
  }

  @override
  int get hashCode => key.hashCode ^ profileType.hashCode;
}

/// generated route for
/// [_i48.TenantAdminProfileTypeEditRoutePage]
class TenantAdminProfileTypeEditRoute
    extends _i74.PageRouteInfo<TenantAdminProfileTypeEditRouteArgs> {
  TenantAdminProfileTypeEditRoute({
    _i75.Key? key,
    required String profileType,
    List<_i74.PageRouteInfo>? children,
  }) : super(
         TenantAdminProfileTypeEditRoute.name,
         args: TenantAdminProfileTypeEditRouteArgs(
           key: key,
           profileType: profileType,
         ),
         rawPathParams: {'profileType': profileType},
         initialChildren: children,
       );

  static const String name = 'TenantAdminProfileTypeEditRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminProfileTypeEditRouteArgs>(
        orElse: () => TenantAdminProfileTypeEditRouteArgs(
          profileType: pathParams.getString('profileType'),
        ),
      );
      return _i48.TenantAdminProfileTypeEditRoutePage(
        key: args.key,
        profileType: args.profileType,
      );
    },
  );
}

class TenantAdminProfileTypeEditRouteArgs {
  const TenantAdminProfileTypeEditRouteArgs({
    this.key,
    required this.profileType,
  });

  final _i75.Key? key;

  final String profileType;

  @override
  String toString() {
    return 'TenantAdminProfileTypeEditRouteArgs{key: $key, profileType: $profileType}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TenantAdminProfileTypeEditRouteArgs) return false;
    return key == other.key && profileType == other.profileType;
  }

  @override
  int get hashCode => key.hashCode ^ profileType.hashCode;
}

/// generated route for
/// [_i49.TenantAdminProfileTypesListRoutePage]
class TenantAdminProfileTypesListRoute extends _i74.PageRouteInfo<void> {
  const TenantAdminProfileTypesListRoute({List<_i74.PageRouteInfo>? children})
    : super(TenantAdminProfileTypesListRoute.name, initialChildren: children);

  static const String name = 'TenantAdminProfileTypesListRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      return const _i49.TenantAdminProfileTypesListRoutePage();
    },
  );
}

/// generated route for
/// [_i50.TenantAdminSettingsDomainsRoutePage]
class TenantAdminSettingsDomainsRoute extends _i74.PageRouteInfo<void> {
  const TenantAdminSettingsDomainsRoute({List<_i74.PageRouteInfo>? children})
    : super(TenantAdminSettingsDomainsRoute.name, initialChildren: children);

  static const String name = 'TenantAdminSettingsDomainsRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      return const _i50.TenantAdminSettingsDomainsRoutePage();
    },
  );
}

/// generated route for
/// [_i51.TenantAdminSettingsEnvironmentSnapshotRoutePage]
class TenantAdminSettingsEnvironmentSnapshotRoute
    extends _i74.PageRouteInfo<void> {
  const TenantAdminSettingsEnvironmentSnapshotRoute({
    List<_i74.PageRouteInfo>? children,
  }) : super(
         TenantAdminSettingsEnvironmentSnapshotRoute.name,
         initialChildren: children,
       );

  static const String name = 'TenantAdminSettingsEnvironmentSnapshotRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      return const _i51.TenantAdminSettingsEnvironmentSnapshotRoutePage();
    },
  );
}

/// generated route for
/// [_i52.TenantAdminSettingsLocalPreferencesRoutePage]
class TenantAdminSettingsLocalPreferencesRoute
    extends _i74.PageRouteInfo<void> {
  const TenantAdminSettingsLocalPreferencesRoute({
    List<_i74.PageRouteInfo>? children,
  }) : super(
         TenantAdminSettingsLocalPreferencesRoute.name,
         initialChildren: children,
       );

  static const String name = 'TenantAdminSettingsLocalPreferencesRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      return const _i52.TenantAdminSettingsLocalPreferencesRoutePage();
    },
  );
}

/// generated route for
/// [_i53.TenantAdminSettingsRoutePage]
class TenantAdminSettingsRoute extends _i74.PageRouteInfo<void> {
  const TenantAdminSettingsRoute({List<_i74.PageRouteInfo>? children})
    : super(TenantAdminSettingsRoute.name, initialChildren: children);

  static const String name = 'TenantAdminSettingsRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      return const _i53.TenantAdminSettingsRoutePage();
    },
  );
}

/// generated route for
/// [_i54.TenantAdminSettingsTechnicalIntegrationsRoutePage]
class TenantAdminSettingsTechnicalIntegrationsRoute
    extends
        _i74.PageRouteInfo<TenantAdminSettingsTechnicalIntegrationsRouteArgs> {
  TenantAdminSettingsTechnicalIntegrationsRoute({
    _i75.Key? key,
    _i82.TenantAdminSettingsIntegrationSection initialSection =
        _i82.TenantAdminSettingsIntegrationSection.firebase,
    List<_i74.PageRouteInfo>? children,
  }) : super(
         TenantAdminSettingsTechnicalIntegrationsRoute.name,
         args: TenantAdminSettingsTechnicalIntegrationsRouteArgs(
           key: key,
           initialSection: initialSection,
         ),
         initialChildren: children,
       );

  static const String name = 'TenantAdminSettingsTechnicalIntegrationsRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      final args = data
          .argsAs<TenantAdminSettingsTechnicalIntegrationsRouteArgs>(
            orElse: () =>
                const TenantAdminSettingsTechnicalIntegrationsRouteArgs(),
          );
      return _i54.TenantAdminSettingsTechnicalIntegrationsRoutePage(
        key: args.key,
        initialSection: args.initialSection,
      );
    },
  );
}

class TenantAdminSettingsTechnicalIntegrationsRouteArgs {
  const TenantAdminSettingsTechnicalIntegrationsRouteArgs({
    this.key,
    this.initialSection = _i82.TenantAdminSettingsIntegrationSection.firebase,
  });

  final _i75.Key? key;

  final _i82.TenantAdminSettingsIntegrationSection initialSection;

  @override
  String toString() {
    return 'TenantAdminSettingsTechnicalIntegrationsRouteArgs{key: $key, initialSection: $initialSection}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TenantAdminSettingsTechnicalIntegrationsRouteArgs)
      return false;
    return key == other.key && initialSection == other.initialSection;
  }

  @override
  int get hashCode => key.hashCode ^ initialSection.hashCode;
}

/// generated route for
/// [_i55.TenantAdminSettingsVisualIdentityRoutePage]
class TenantAdminSettingsVisualIdentityRoute extends _i74.PageRouteInfo<void> {
  const TenantAdminSettingsVisualIdentityRoute({
    List<_i74.PageRouteInfo>? children,
  }) : super(
         TenantAdminSettingsVisualIdentityRoute.name,
         initialChildren: children,
       );

  static const String name = 'TenantAdminSettingsVisualIdentityRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      return const _i55.TenantAdminSettingsVisualIdentityRoutePage();
    },
  );
}

/// generated route for
/// [_i56.TenantAdminShellRoutePage]
class TenantAdminShellRoute extends _i74.PageRouteInfo<void> {
  const TenantAdminShellRoute({List<_i74.PageRouteInfo>? children})
    : super(TenantAdminShellRoute.name, initialChildren: children);

  static const String name = 'TenantAdminShellRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      return const _i56.TenantAdminShellRoutePage();
    },
  );
}

/// generated route for
/// [_i57.TenantAdminStaticAssetCreateRoutePage]
class TenantAdminStaticAssetCreateRoute extends _i74.PageRouteInfo<void> {
  const TenantAdminStaticAssetCreateRoute({List<_i74.PageRouteInfo>? children})
    : super(TenantAdminStaticAssetCreateRoute.name, initialChildren: children);

  static const String name = 'TenantAdminStaticAssetCreateRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      return const _i57.TenantAdminStaticAssetCreateRoutePage();
    },
  );
}

/// generated route for
/// [_i58.TenantAdminStaticAssetDetailRoutePage]
class TenantAdminStaticAssetDetailRoute
    extends _i74.PageRouteInfo<TenantAdminStaticAssetDetailRouteArgs> {
  TenantAdminStaticAssetDetailRoute({
    _i75.Key? key,
    required String assetId,
    List<_i74.PageRouteInfo>? children,
  }) : super(
         TenantAdminStaticAssetDetailRoute.name,
         args: TenantAdminStaticAssetDetailRouteArgs(
           key: key,
           assetId: assetId,
         ),
         rawPathParams: {'assetId': assetId},
         initialChildren: children,
       );

  static const String name = 'TenantAdminStaticAssetDetailRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminStaticAssetDetailRouteArgs>(
        orElse: () => TenantAdminStaticAssetDetailRouteArgs(
          assetId: pathParams.getString('assetId'),
        ),
      );
      return _i58.TenantAdminStaticAssetDetailRoutePage(
        key: args.key,
        assetId: args.assetId,
      );
    },
  );
}

class TenantAdminStaticAssetDetailRouteArgs {
  const TenantAdminStaticAssetDetailRouteArgs({
    this.key,
    required this.assetId,
  });

  final _i75.Key? key;

  final String assetId;

  @override
  String toString() {
    return 'TenantAdminStaticAssetDetailRouteArgs{key: $key, assetId: $assetId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TenantAdminStaticAssetDetailRouteArgs) return false;
    return key == other.key && assetId == other.assetId;
  }

  @override
  int get hashCode => key.hashCode ^ assetId.hashCode;
}

/// generated route for
/// [_i59.TenantAdminStaticAssetEditRoutePage]
class TenantAdminStaticAssetEditRoute
    extends _i74.PageRouteInfo<TenantAdminStaticAssetEditRouteArgs> {
  TenantAdminStaticAssetEditRoute({
    _i75.Key? key,
    required String assetId,
    List<_i74.PageRouteInfo>? children,
  }) : super(
         TenantAdminStaticAssetEditRoute.name,
         args: TenantAdminStaticAssetEditRouteArgs(key: key, assetId: assetId),
         rawPathParams: {'assetId': assetId},
         initialChildren: children,
       );

  static const String name = 'TenantAdminStaticAssetEditRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminStaticAssetEditRouteArgs>(
        orElse: () => TenantAdminStaticAssetEditRouteArgs(
          assetId: pathParams.getString('assetId'),
        ),
      );
      return _i59.TenantAdminStaticAssetEditRoutePage(
        key: args.key,
        assetId: args.assetId,
      );
    },
  );
}

class TenantAdminStaticAssetEditRouteArgs {
  const TenantAdminStaticAssetEditRouteArgs({this.key, required this.assetId});

  final _i75.Key? key;

  final String assetId;

  @override
  String toString() {
    return 'TenantAdminStaticAssetEditRouteArgs{key: $key, assetId: $assetId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TenantAdminStaticAssetEditRouteArgs) return false;
    return key == other.key && assetId == other.assetId;
  }

  @override
  int get hashCode => key.hashCode ^ assetId.hashCode;
}

/// generated route for
/// [_i60.TenantAdminStaticAssetsListRoutePage]
class TenantAdminStaticAssetsListRoute extends _i74.PageRouteInfo<void> {
  const TenantAdminStaticAssetsListRoute({List<_i74.PageRouteInfo>? children})
    : super(TenantAdminStaticAssetsListRoute.name, initialChildren: children);

  static const String name = 'TenantAdminStaticAssetsListRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      return const _i60.TenantAdminStaticAssetsListRoutePage();
    },
  );
}

/// generated route for
/// [_i61.TenantAdminStaticProfileTypeCreateRoutePage]
class TenantAdminStaticProfileTypeCreateRoute extends _i74.PageRouteInfo<void> {
  const TenantAdminStaticProfileTypeCreateRoute({
    List<_i74.PageRouteInfo>? children,
  }) : super(
         TenantAdminStaticProfileTypeCreateRoute.name,
         initialChildren: children,
       );

  static const String name = 'TenantAdminStaticProfileTypeCreateRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      return const _i61.TenantAdminStaticProfileTypeCreateRoutePage();
    },
  );
}

/// generated route for
/// [_i62.TenantAdminStaticProfileTypeDetailRoutePage]
class TenantAdminStaticProfileTypeDetailRoute
    extends _i74.PageRouteInfo<TenantAdminStaticProfileTypeDetailRouteArgs> {
  TenantAdminStaticProfileTypeDetailRoute({
    _i75.Key? key,
    required String profileType,
    List<_i74.PageRouteInfo>? children,
  }) : super(
         TenantAdminStaticProfileTypeDetailRoute.name,
         args: TenantAdminStaticProfileTypeDetailRouteArgs(
           key: key,
           profileType: profileType,
         ),
         rawPathParams: {'profileType': profileType},
         initialChildren: children,
       );

  static const String name = 'TenantAdminStaticProfileTypeDetailRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminStaticProfileTypeDetailRouteArgs>(
        orElse: () => TenantAdminStaticProfileTypeDetailRouteArgs(
          profileType: pathParams.getString('profileType'),
        ),
      );
      return _i62.TenantAdminStaticProfileTypeDetailRoutePage(
        key: args.key,
        profileType: args.profileType,
      );
    },
  );
}

class TenantAdminStaticProfileTypeDetailRouteArgs {
  const TenantAdminStaticProfileTypeDetailRouteArgs({
    this.key,
    required this.profileType,
  });

  final _i75.Key? key;

  final String profileType;

  @override
  String toString() {
    return 'TenantAdminStaticProfileTypeDetailRouteArgs{key: $key, profileType: $profileType}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TenantAdminStaticProfileTypeDetailRouteArgs) return false;
    return key == other.key && profileType == other.profileType;
  }

  @override
  int get hashCode => key.hashCode ^ profileType.hashCode;
}

/// generated route for
/// [_i63.TenantAdminStaticProfileTypeEditRoutePage]
class TenantAdminStaticProfileTypeEditRoute
    extends _i74.PageRouteInfo<TenantAdminStaticProfileTypeEditRouteArgs> {
  TenantAdminStaticProfileTypeEditRoute({
    _i75.Key? key,
    required String profileType,
    List<_i74.PageRouteInfo>? children,
  }) : super(
         TenantAdminStaticProfileTypeEditRoute.name,
         args: TenantAdminStaticProfileTypeEditRouteArgs(
           key: key,
           profileType: profileType,
         ),
         rawPathParams: {'profileType': profileType},
         initialChildren: children,
       );

  static const String name = 'TenantAdminStaticProfileTypeEditRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminStaticProfileTypeEditRouteArgs>(
        orElse: () => TenantAdminStaticProfileTypeEditRouteArgs(
          profileType: pathParams.getString('profileType'),
        ),
      );
      return _i63.TenantAdminStaticProfileTypeEditRoutePage(
        key: args.key,
        profileType: args.profileType,
      );
    },
  );
}

class TenantAdminStaticProfileTypeEditRouteArgs {
  const TenantAdminStaticProfileTypeEditRouteArgs({
    this.key,
    required this.profileType,
  });

  final _i75.Key? key;

  final String profileType;

  @override
  String toString() {
    return 'TenantAdminStaticProfileTypeEditRouteArgs{key: $key, profileType: $profileType}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TenantAdminStaticProfileTypeEditRouteArgs) return false;
    return key == other.key && profileType == other.profileType;
  }

  @override
  int get hashCode => key.hashCode ^ profileType.hashCode;
}

/// generated route for
/// [_i64.TenantAdminStaticProfileTypesListRoutePage]
class TenantAdminStaticProfileTypesListRoute extends _i74.PageRouteInfo<void> {
  const TenantAdminStaticProfileTypesListRoute({
    List<_i74.PageRouteInfo>? children,
  }) : super(
         TenantAdminStaticProfileTypesListRoute.name,
         initialChildren: children,
       );

  static const String name = 'TenantAdminStaticProfileTypesListRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      return const _i64.TenantAdminStaticProfileTypesListRoutePage();
    },
  );
}

/// generated route for
/// [_i65.TenantAdminTaxonomiesListRoutePage]
class TenantAdminTaxonomiesListRoute extends _i74.PageRouteInfo<void> {
  const TenantAdminTaxonomiesListRoute({List<_i74.PageRouteInfo>? children})
    : super(TenantAdminTaxonomiesListRoute.name, initialChildren: children);

  static const String name = 'TenantAdminTaxonomiesListRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      return const _i65.TenantAdminTaxonomiesListRoutePage();
    },
  );
}

/// generated route for
/// [_i66.TenantAdminTaxonomyCreateRoutePage]
class TenantAdminTaxonomyCreateRoute extends _i74.PageRouteInfo<void> {
  const TenantAdminTaxonomyCreateRoute({List<_i74.PageRouteInfo>? children})
    : super(TenantAdminTaxonomyCreateRoute.name, initialChildren: children);

  static const String name = 'TenantAdminTaxonomyCreateRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      return const _i66.TenantAdminTaxonomyCreateRoutePage();
    },
  );
}

/// generated route for
/// [_i67.TenantAdminTaxonomyEditRoutePage]
class TenantAdminTaxonomyEditRoute
    extends _i74.PageRouteInfo<TenantAdminTaxonomyEditRouteArgs> {
  TenantAdminTaxonomyEditRoute({
    _i75.Key? key,
    required String taxonomyId,
    List<_i74.PageRouteInfo>? children,
  }) : super(
         TenantAdminTaxonomyEditRoute.name,
         args: TenantAdminTaxonomyEditRouteArgs(
           key: key,
           taxonomyId: taxonomyId,
         ),
         rawPathParams: {'taxonomyId': taxonomyId},
         initialChildren: children,
       );

  static const String name = 'TenantAdminTaxonomyEditRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminTaxonomyEditRouteArgs>(
        orElse: () => TenantAdminTaxonomyEditRouteArgs(
          taxonomyId: pathParams.getString('taxonomyId'),
        ),
      );
      return _i67.TenantAdminTaxonomyEditRoutePage(
        key: args.key,
        taxonomyId: args.taxonomyId,
      );
    },
  );
}

class TenantAdminTaxonomyEditRouteArgs {
  const TenantAdminTaxonomyEditRouteArgs({this.key, required this.taxonomyId});

  final _i75.Key? key;

  final String taxonomyId;

  @override
  String toString() {
    return 'TenantAdminTaxonomyEditRouteArgs{key: $key, taxonomyId: $taxonomyId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TenantAdminTaxonomyEditRouteArgs) return false;
    return key == other.key && taxonomyId == other.taxonomyId;
  }

  @override
  int get hashCode => key.hashCode ^ taxonomyId.hashCode;
}

/// generated route for
/// [_i68.TenantAdminTaxonomyTermCreateRoutePage]
class TenantAdminTaxonomyTermCreateRoute
    extends _i74.PageRouteInfo<TenantAdminTaxonomyTermCreateRouteArgs> {
  TenantAdminTaxonomyTermCreateRoute({
    _i75.Key? key,
    required String taxonomyId,
    List<_i74.PageRouteInfo>? children,
  }) : super(
         TenantAdminTaxonomyTermCreateRoute.name,
         args: TenantAdminTaxonomyTermCreateRouteArgs(
           key: key,
           taxonomyId: taxonomyId,
         ),
         rawPathParams: {'taxonomyId': taxonomyId},
         initialChildren: children,
       );

  static const String name = 'TenantAdminTaxonomyTermCreateRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminTaxonomyTermCreateRouteArgs>(
        orElse: () => TenantAdminTaxonomyTermCreateRouteArgs(
          taxonomyId: pathParams.getString('taxonomyId'),
        ),
      );
      return _i68.TenantAdminTaxonomyTermCreateRoutePage(
        key: args.key,
        taxonomyId: args.taxonomyId,
      );
    },
  );
}

class TenantAdminTaxonomyTermCreateRouteArgs {
  const TenantAdminTaxonomyTermCreateRouteArgs({
    this.key,
    required this.taxonomyId,
  });

  final _i75.Key? key;

  final String taxonomyId;

  @override
  String toString() {
    return 'TenantAdminTaxonomyTermCreateRouteArgs{key: $key, taxonomyId: $taxonomyId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TenantAdminTaxonomyTermCreateRouteArgs) return false;
    return key == other.key && taxonomyId == other.taxonomyId;
  }

  @override
  int get hashCode => key.hashCode ^ taxonomyId.hashCode;
}

/// generated route for
/// [_i69.TenantAdminTaxonomyTermDetailRoutePage]
class TenantAdminTaxonomyTermDetailRoute
    extends _i74.PageRouteInfo<TenantAdminTaxonomyTermDetailRouteArgs> {
  TenantAdminTaxonomyTermDetailRoute({
    _i75.Key? key,
    required String taxonomyId,
    required String termId,
    List<_i74.PageRouteInfo>? children,
  }) : super(
         TenantAdminTaxonomyTermDetailRoute.name,
         args: TenantAdminTaxonomyTermDetailRouteArgs(
           key: key,
           taxonomyId: taxonomyId,
           termId: termId,
         ),
         rawPathParams: {'taxonomyId': taxonomyId, 'termId': termId},
         initialChildren: children,
       );

  static const String name = 'TenantAdminTaxonomyTermDetailRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminTaxonomyTermDetailRouteArgs>(
        orElse: () => TenantAdminTaxonomyTermDetailRouteArgs(
          taxonomyId: pathParams.getString('taxonomyId'),
          termId: pathParams.getString('termId'),
        ),
      );
      return _i69.TenantAdminTaxonomyTermDetailRoutePage(
        key: args.key,
        taxonomyId: args.taxonomyId,
        termId: args.termId,
      );
    },
  );
}

class TenantAdminTaxonomyTermDetailRouteArgs {
  const TenantAdminTaxonomyTermDetailRouteArgs({
    this.key,
    required this.taxonomyId,
    required this.termId,
  });

  final _i75.Key? key;

  final String taxonomyId;

  final String termId;

  @override
  String toString() {
    return 'TenantAdminTaxonomyTermDetailRouteArgs{key: $key, taxonomyId: $taxonomyId, termId: $termId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TenantAdminTaxonomyTermDetailRouteArgs) return false;
    return key == other.key &&
        taxonomyId == other.taxonomyId &&
        termId == other.termId;
  }

  @override
  int get hashCode => key.hashCode ^ taxonomyId.hashCode ^ termId.hashCode;
}

/// generated route for
/// [_i70.TenantAdminTaxonomyTermEditRoutePage]
class TenantAdminTaxonomyTermEditRoute
    extends _i74.PageRouteInfo<TenantAdminTaxonomyTermEditRouteArgs> {
  TenantAdminTaxonomyTermEditRoute({
    _i75.Key? key,
    required String taxonomyId,
    required String termId,
    List<_i74.PageRouteInfo>? children,
  }) : super(
         TenantAdminTaxonomyTermEditRoute.name,
         args: TenantAdminTaxonomyTermEditRouteArgs(
           key: key,
           taxonomyId: taxonomyId,
           termId: termId,
         ),
         rawPathParams: {'taxonomyId': taxonomyId, 'termId': termId},
         initialChildren: children,
       );

  static const String name = 'TenantAdminTaxonomyTermEditRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminTaxonomyTermEditRouteArgs>(
        orElse: () => TenantAdminTaxonomyTermEditRouteArgs(
          taxonomyId: pathParams.getString('taxonomyId'),
          termId: pathParams.getString('termId'),
        ),
      );
      return _i70.TenantAdminTaxonomyTermEditRoutePage(
        key: args.key,
        taxonomyId: args.taxonomyId,
        termId: args.termId,
      );
    },
  );
}

class TenantAdminTaxonomyTermEditRouteArgs {
  const TenantAdminTaxonomyTermEditRouteArgs({
    this.key,
    required this.taxonomyId,
    required this.termId,
  });

  final _i75.Key? key;

  final String taxonomyId;

  final String termId;

  @override
  String toString() {
    return 'TenantAdminTaxonomyTermEditRouteArgs{key: $key, taxonomyId: $taxonomyId, termId: $termId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TenantAdminTaxonomyTermEditRouteArgs) return false;
    return key == other.key &&
        taxonomyId == other.taxonomyId &&
        termId == other.termId;
  }

  @override
  int get hashCode => key.hashCode ^ taxonomyId.hashCode ^ termId.hashCode;
}

/// generated route for
/// [_i71.TenantAdminTaxonomyTermsRoutePage]
class TenantAdminTaxonomyTermsRoute
    extends _i74.PageRouteInfo<TenantAdminTaxonomyTermsRouteArgs> {
  TenantAdminTaxonomyTermsRoute({
    _i75.Key? key,
    required String taxonomyId,
    List<_i74.PageRouteInfo>? children,
  }) : super(
         TenantAdminTaxonomyTermsRoute.name,
         args: TenantAdminTaxonomyTermsRouteArgs(
           key: key,
           taxonomyId: taxonomyId,
         ),
         rawPathParams: {'taxonomyId': taxonomyId},
         initialChildren: children,
       );

  static const String name = 'TenantAdminTaxonomyTermsRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminTaxonomyTermsRouteArgs>(
        orElse: () => TenantAdminTaxonomyTermsRouteArgs(
          taxonomyId: pathParams.getString('taxonomyId'),
        ),
      );
      return _i71.TenantAdminTaxonomyTermsRoutePage(
        key: args.key,
        taxonomyId: args.taxonomyId,
      );
    },
  );
}

class TenantAdminTaxonomyTermsRouteArgs {
  const TenantAdminTaxonomyTermsRouteArgs({this.key, required this.taxonomyId});

  final _i75.Key? key;

  final String taxonomyId;

  @override
  String toString() {
    return 'TenantAdminTaxonomyTermsRouteArgs{key: $key, taxonomyId: $taxonomyId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TenantAdminTaxonomyTermsRouteArgs) return false;
    return key == other.key && taxonomyId == other.taxonomyId;
  }

  @override
  int get hashCode => key.hashCode ^ taxonomyId.hashCode;
}

/// generated route for
/// [_i72.TenantHomeRoutePage]
class TenantHomeRoute extends _i74.PageRouteInfo<void> {
  const TenantHomeRoute({List<_i74.PageRouteInfo>? children})
    : super(TenantHomeRoute.name, initialChildren: children);

  static const String name = 'TenantHomeRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      return const _i72.TenantHomeRoutePage();
    },
  );
}

/// generated route for
/// [_i73.TenantPrivacyPolicyRoutePage]
class TenantPrivacyPolicyRoute extends _i74.PageRouteInfo<void> {
  const TenantPrivacyPolicyRoute({List<_i74.PageRouteInfo>? children})
    : super(TenantPrivacyPolicyRoute.name, initialChildren: children);

  static const String name = 'TenantPrivacyPolicyRoute';

  static _i74.PageInfo page = _i74.PageInfo(
    name,
    builder: (data) {
      return const _i73.TenantPrivacyPolicyRoutePage();
    },
  );
}
