// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i64;
import 'package:belluga_now/application/router/guards/location_permission_gate_result.dart'
    as _i69;
import 'package:belluga_now/application/router/guards/location_permission_state.dart'
    as _i68;
import 'package:belluga_now/domain/invites/invite_model.dart' as _i67;
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart'
    as _i70;
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart'
    as _i71;
import 'package:belluga_now/presentation/account_workspace/routes/account_workspace_create_event_route.dart'
    as _i1;
import 'package:belluga_now/presentation/account_workspace/routes/account_workspace_home_route.dart'
    as _i2;
import 'package:belluga_now/presentation/account_workspace/routes/account_workspace_scoped_route.dart'
    as _i3;
import 'package:belluga_now/presentation/landlord_area/home/routes/landlord_home_route.dart'
    as _i15;
import 'package:belluga_now/presentation/shared/auth/routes/auth_create_new_password_route.dart'
    as _i5;
import 'package:belluga_now/presentation/shared/auth/routes/auth_login_route.dart'
    as _i6;
import 'package:belluga_now/presentation/shared/auth/routes/recovery_password_route.dart'
    as _i20;
import 'package:belluga_now/presentation/shared/init/routes/init_route.dart'
    as _i11;
import 'package:belluga_now/presentation/shared/location_permission/routes/location_permission_route.dart'
    as _i16;
import 'package:belluga_now/presentation/shared/promotion/routes/app_promotion_route.dart'
    as _i4;
import 'package:belluga_now/presentation/tenant_admin/account_profiles/routes/tenant_admin_account_profile_create_route.dart'
    as _i23;
import 'package:belluga_now/presentation/tenant_admin/account_profiles/routes/tenant_admin_account_profile_edit_route.dart'
    as _i24;
import 'package:belluga_now/presentation/tenant_admin/accounts/routes/tenant_admin_account_create_route.dart'
    as _i21;
import 'package:belluga_now/presentation/tenant_admin/accounts/routes/tenant_admin_account_detail_route.dart'
    as _i22;
import 'package:belluga_now/presentation/tenant_admin/accounts/routes/tenant_admin_accounts_list_route.dart'
    as _i25;
import 'package:belluga_now/presentation/tenant_admin/accounts/routes/tenant_admin_location_picker_route.dart'
    as _i33;
import 'package:belluga_now/presentation/tenant_admin/events/routes/tenant_admin_event_create_route.dart'
    as _i27;
import 'package:belluga_now/presentation/tenant_admin/events/routes/tenant_admin_event_edit_route.dart'
    as _i28;
import 'package:belluga_now/presentation/tenant_admin/events/routes/tenant_admin_event_type_create_route.dart'
    as _i29;
import 'package:belluga_now/presentation/tenant_admin/events/routes/tenant_admin_event_type_edit_route.dart'
    as _i30;
import 'package:belluga_now/presentation/tenant_admin/events/routes/tenant_admin_event_types_route.dart'
    as _i31;
import 'package:belluga_now/presentation/tenant_admin/events/routes/tenant_admin_events_route.dart'
    as _i32;
import 'package:belluga_now/presentation/tenant_admin/organizations/routes/tenant_admin_organization_create_route.dart'
    as _i34;
import 'package:belluga_now/presentation/tenant_admin/organizations/routes/tenant_admin_organization_detail_route.dart'
    as _i35;
import 'package:belluga_now/presentation/tenant_admin/organizations/routes/tenant_admin_organizations_list_route.dart'
    as _i36;
import 'package:belluga_now/presentation/tenant_admin/profile_types/routes/tenant_admin_profile_type_create_route.dart'
    as _i37;
import 'package:belluga_now/presentation/tenant_admin/profile_types/routes/tenant_admin_profile_type_detail_route.dart'
    as _i38;
import 'package:belluga_now/presentation/tenant_admin/profile_types/routes/tenant_admin_profile_type_edit_route.dart'
    as _i39;
import 'package:belluga_now/presentation/tenant_admin/profile_types/routes/tenant_admin_profile_types_list_route.dart'
    as _i40;
import 'package:belluga_now/presentation/tenant_admin/settings/models/tenant_admin_settings_integration_section.dart'
    as _i72;
import 'package:belluga_now/presentation/tenant_admin/settings/routes/tenant_admin_settings_environment_snapshot_route.dart'
    as _i41;
import 'package:belluga_now/presentation/tenant_admin/settings/routes/tenant_admin_settings_local_preferences_route.dart'
    as _i42;
import 'package:belluga_now/presentation/tenant_admin/settings/routes/tenant_admin_settings_route.dart'
    as _i43;
import 'package:belluga_now/presentation/tenant_admin/settings/routes/tenant_admin_settings_technical_integrations_route.dart'
    as _i44;
import 'package:belluga_now/presentation/tenant_admin/settings/routes/tenant_admin_settings_visual_identity_route.dart'
    as _i45;
import 'package:belluga_now/presentation/tenant_admin/shell/routes/tenant_admin_dashboard_route.dart'
    as _i26;
import 'package:belluga_now/presentation/tenant_admin/shell/routes/tenant_admin_shell_route.dart'
    as _i46;
import 'package:belluga_now/presentation/tenant_admin/static_assets/routes/tenant_admin_static_asset_create_route.dart'
    as _i47;
import 'package:belluga_now/presentation/tenant_admin/static_assets/routes/tenant_admin_static_asset_detail_route.dart'
    as _i48;
import 'package:belluga_now/presentation/tenant_admin/static_assets/routes/tenant_admin_static_asset_edit_route.dart'
    as _i49;
import 'package:belluga_now/presentation/tenant_admin/static_assets/routes/tenant_admin_static_assets_list_route.dart'
    as _i50;
import 'package:belluga_now/presentation/tenant_admin/static_profile_types/routes/tenant_admin_static_profile_type_create_route.dart'
    as _i51;
import 'package:belluga_now/presentation/tenant_admin/static_profile_types/routes/tenant_admin_static_profile_type_detail_route.dart'
    as _i52;
import 'package:belluga_now/presentation/tenant_admin/static_profile_types/routes/tenant_admin_static_profile_type_edit_route.dart'
    as _i53;
import 'package:belluga_now/presentation/tenant_admin/static_profile_types/routes/tenant_admin_static_profile_types_list_route.dart'
    as _i54;
import 'package:belluga_now/presentation/tenant_admin/taxonomies/routes/tenant_admin_taxonomies_list_route.dart'
    as _i55;
import 'package:belluga_now/presentation/tenant_admin/taxonomies/routes/tenant_admin_taxonomy_create_route_page.dart'
    as _i56;
import 'package:belluga_now/presentation/tenant_admin/taxonomies/routes/tenant_admin_taxonomy_edit_route_page.dart'
    as _i57;
import 'package:belluga_now/presentation/tenant_admin/taxonomies/routes/tenant_admin_taxonomy_term_create_route_page.dart'
    as _i58;
import 'package:belluga_now/presentation/tenant_admin/taxonomies/routes/tenant_admin_taxonomy_term_detail_route.dart'
    as _i59;
import 'package:belluga_now/presentation/tenant_admin/taxonomies/routes/tenant_admin_taxonomy_term_edit_route_page.dart'
    as _i60;
import 'package:belluga_now/presentation/tenant_admin/taxonomies/routes/tenant_admin_taxonomy_terms_route.dart'
    as _i61;
import 'package:belluga_now/presentation/tenant_public/discovery/routes/discovery_route.dart'
    as _i8;
import 'package:belluga_now/presentation/tenant_public/home/routes/tenant_home_route.dart'
    as _i62;
import 'package:belluga_now/presentation/tenant_public/invites/routes/invite_entry_route.dart'
    as _i12;
import 'package:belluga_now/presentation/tenant_public/invites/routes/invite_flow_route.dart'
    as _i13;
import 'package:belluga_now/presentation/tenant_public/invites/routes/invite_share_route.dart'
    as _i14;
import 'package:belluga_now/presentation/tenant_public/legal/routes/tenant_privacy_policy_route.dart'
    as _i63;
import 'package:belluga_now/presentation/tenant_public/map/routes/city_map_route.dart'
    as _i7;
import 'package:belluga_now/presentation/tenant_public/map/routes/poi_details_route.dart'
    as _i18;
import 'package:belluga_now/presentation/tenant_public/partners/routes/partner_detail_route.dart'
    as _i17;
import 'package:belluga_now/presentation/tenant_public/profile/routes/profile_route.dart'
    as _i19;
import 'package:belluga_now/presentation/tenant_public/schedule/routes/event_search_route.dart'
    as _i9;
import 'package:belluga_now/presentation/tenant_public/schedule/routes/immersive_event_detail_route.dart'
    as _i10;
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/models/invite_filter.dart'
    as _i66;
import 'package:flutter/material.dart' as _i65;

/// generated route for
/// [_i1.AccountWorkspaceCreateEventRoutePage]
class AccountWorkspaceCreateEventRoute
    extends _i64.PageRouteInfo<AccountWorkspaceCreateEventRouteArgs> {
  AccountWorkspaceCreateEventRoute({
    required String accountSlug,
    _i65.Key? key,
    List<_i64.PageRouteInfo>? children,
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

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<AccountWorkspaceCreateEventRouteArgs>(
        orElse: () => AccountWorkspaceCreateEventRouteArgs(
          accountSlug: pathParams.getString('accountSlug'),
        ),
      );
      return _i1.AccountWorkspaceCreateEventRoutePage(
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

  final _i65.Key? key;

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
/// [_i2.AccountWorkspaceHomeRoutePage]
class AccountWorkspaceHomeRoute extends _i64.PageRouteInfo<void> {
  const AccountWorkspaceHomeRoute({List<_i64.PageRouteInfo>? children})
      : super(AccountWorkspaceHomeRoute.name, initialChildren: children);

  static const String name = 'AccountWorkspaceHomeRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i2.AccountWorkspaceHomeRoutePage();
    },
  );
}

/// generated route for
/// [_i3.AccountWorkspaceScopedRoutePage]
class AccountWorkspaceScopedRoute
    extends _i64.PageRouteInfo<AccountWorkspaceScopedRouteArgs> {
  AccountWorkspaceScopedRoute({
    required String accountSlug,
    _i65.Key? key,
    List<_i64.PageRouteInfo>? children,
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

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<AccountWorkspaceScopedRouteArgs>(
        orElse: () => AccountWorkspaceScopedRouteArgs(
          accountSlug: pathParams.getString('accountSlug'),
        ),
      );
      return _i3.AccountWorkspaceScopedRoutePage(
        accountSlug: args.accountSlug,
        key: args.key,
      );
    },
  );
}

class AccountWorkspaceScopedRouteArgs {
  const AccountWorkspaceScopedRouteArgs({required this.accountSlug, this.key});

  final String accountSlug;

  final _i65.Key? key;

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
/// [_i4.AppPromotionRoutePage]
class AppPromotionRoute extends _i64.PageRouteInfo<AppPromotionRouteArgs> {
  AppPromotionRoute({
    _i65.Key? key,
    String? redirectPath,
    List<_i64.PageRouteInfo>? children,
  }) : super(
          AppPromotionRoute.name,
          args: AppPromotionRouteArgs(key: key, redirectPath: redirectPath),
          rawQueryParams: {'redirect': redirectPath},
          initialChildren: children,
        );

  static const String name = 'AppPromotionRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final queryParams = data.queryParams;
      final args = data.argsAs<AppPromotionRouteArgs>(
        orElse: () => AppPromotionRouteArgs(
          redirectPath: queryParams.optString('redirect'),
        ),
      );
      return _i4.AppPromotionRoutePage(
        key: args.key,
        redirectPath: args.redirectPath,
      );
    },
  );
}

class AppPromotionRouteArgs {
  const AppPromotionRouteArgs({this.key, this.redirectPath});

  final _i65.Key? key;

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
/// [_i5.AuthCreateNewPasswordRoutePage]
class AuthCreateNewPasswordRoute extends _i64.PageRouteInfo<void> {
  const AuthCreateNewPasswordRoute({List<_i64.PageRouteInfo>? children})
      : super(AuthCreateNewPasswordRoute.name, initialChildren: children);

  static const String name = 'AuthCreateNewPasswordRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i5.AuthCreateNewPasswordRoutePage();
    },
  );
}

/// generated route for
/// [_i6.AuthLoginRoutePage]
class AuthLoginRoute extends _i64.PageRouteInfo<AuthLoginRouteArgs> {
  AuthLoginRoute({
    _i65.Key? key,
    String? redirectPath,
    List<_i64.PageRouteInfo>? children,
  }) : super(
          AuthLoginRoute.name,
          args: AuthLoginRouteArgs(key: key, redirectPath: redirectPath),
          rawQueryParams: {'redirect': redirectPath},
          initialChildren: children,
        );

  static const String name = 'AuthLoginRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final queryParams = data.queryParams;
      final args = data.argsAs<AuthLoginRouteArgs>(
        orElse: () =>
            AuthLoginRouteArgs(redirectPath: queryParams.optString('redirect')),
      );
      return _i6.AuthLoginRoutePage(
        key: args.key,
        redirectPath: args.redirectPath,
      );
    },
  );
}

class AuthLoginRouteArgs {
  const AuthLoginRouteArgs({this.key, this.redirectPath});

  final _i65.Key? key;

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
/// [_i7.CityMapRoutePage]
class CityMapRoute extends _i64.PageRouteInfo<CityMapRouteArgs> {
  CityMapRoute({
    _i65.Key? key,
    String? poi,
    String? stack,
    List<_i64.PageRouteInfo>? children,
  }) : super(
          CityMapRoute.name,
          args: CityMapRouteArgs(key: key, poi: poi, stack: stack),
          rawQueryParams: {'poi': poi, 'stack': stack},
          initialChildren: children,
        );

  static const String name = 'CityMapRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final queryParams = data.queryParams;
      final args = data.argsAs<CityMapRouteArgs>(
        orElse: () => CityMapRouteArgs(
          poi: queryParams.optString('poi'),
          stack: queryParams.optString('stack'),
        ),
      );
      return _i7.CityMapRoutePage(
        key: args.key,
        poi: args.poi,
        stack: args.stack,
      );
    },
  );
}

class CityMapRouteArgs {
  const CityMapRouteArgs({this.key, this.poi, this.stack});

  final _i65.Key? key;

  final String? poi;

  final String? stack;

  @override
  String toString() {
    return 'CityMapRouteArgs{key: $key, poi: $poi, stack: $stack}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CityMapRouteArgs) return false;
    return key == other.key && poi == other.poi && stack == other.stack;
  }

  @override
  int get hashCode => key.hashCode ^ poi.hashCode ^ stack.hashCode;
}

/// generated route for
/// [_i8.DiscoveryRoute]
class DiscoveryRoute extends _i64.PageRouteInfo<void> {
  const DiscoveryRoute({List<_i64.PageRouteInfo>? children})
      : super(DiscoveryRoute.name, initialChildren: children);

  static const String name = 'DiscoveryRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i8.DiscoveryRoute();
    },
  );
}

/// generated route for
/// [_i9.EventSearchRoute]
class EventSearchRoute extends _i64.PageRouteInfo<EventSearchRouteArgs> {
  EventSearchRoute({
    _i65.Key? key,
    _i66.InviteFilter inviteFilter = _i66.InviteFilter.none,
    bool startWithHistory = false,
    List<_i64.PageRouteInfo>? children,
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

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<EventSearchRouteArgs>(
        orElse: () => const EventSearchRouteArgs(),
      );
      return _i9.EventSearchRoute(
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
    this.inviteFilter = _i66.InviteFilter.none,
    this.startWithHistory = false,
  });

  final _i65.Key? key;

  final _i66.InviteFilter inviteFilter;

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
/// [_i10.ImmersiveEventDetailRoutePage]
class ImmersiveEventDetailRoute
    extends _i64.PageRouteInfo<ImmersiveEventDetailRouteArgs> {
  ImmersiveEventDetailRoute({
    _i65.Key? key,
    required String eventSlug,
    List<_i64.PageRouteInfo>? children,
  }) : super(
          ImmersiveEventDetailRoute.name,
          args: ImmersiveEventDetailRouteArgs(key: key, eventSlug: eventSlug),
          rawPathParams: {'slug': eventSlug},
          initialChildren: children,
        );

  static const String name = 'ImmersiveEventDetailRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<ImmersiveEventDetailRouteArgs>(
        orElse: () => ImmersiveEventDetailRouteArgs(
          eventSlug: pathParams.getString('slug'),
        ),
      );
      return _i10.ImmersiveEventDetailRoutePage(
        key: args.key,
        eventSlug: args.eventSlug,
      );
    },
  );
}

class ImmersiveEventDetailRouteArgs {
  const ImmersiveEventDetailRouteArgs({this.key, required this.eventSlug});

  final _i65.Key? key;

  final String eventSlug;

  @override
  String toString() {
    return 'ImmersiveEventDetailRouteArgs{key: $key, eventSlug: $eventSlug}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ImmersiveEventDetailRouteArgs) return false;
    return key == other.key && eventSlug == other.eventSlug;
  }

  @override
  int get hashCode => key.hashCode ^ eventSlug.hashCode;
}

/// generated route for
/// [_i11.InitRoutePage]
class InitRoute extends _i64.PageRouteInfo<void> {
  const InitRoute({List<_i64.PageRouteInfo>? children})
      : super(InitRoute.name, initialChildren: children);

  static const String name = 'InitRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i11.InitRoutePage();
    },
  );
}

/// generated route for
/// [_i12.InviteEntryRoutePage]
class InviteEntryRoute extends _i64.PageRouteInfo<void> {
  const InviteEntryRoute({List<_i64.PageRouteInfo>? children})
      : super(InviteEntryRoute.name, initialChildren: children);

  static const String name = 'InviteEntryRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i12.InviteEntryRoutePage();
    },
  );
}

/// generated route for
/// [_i13.InviteFlowRoutePage]
class InviteFlowRoute extends _i64.PageRouteInfo<void> {
  const InviteFlowRoute({List<_i64.PageRouteInfo>? children})
      : super(InviteFlowRoute.name, initialChildren: children);

  static const String name = 'InviteFlowRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i13.InviteFlowRoutePage();
    },
  );
}

/// generated route for
/// [_i14.InviteShareRoutePage]
class InviteShareRoute extends _i64.PageRouteInfo<InviteShareRouteArgs> {
  InviteShareRoute({
    _i65.Key? key,
    _i67.InviteModel? invite,
    List<_i64.PageRouteInfo>? children,
  }) : super(
          InviteShareRoute.name,
          args: InviteShareRouteArgs(key: key, invite: invite),
          initialChildren: children,
        );

  static const String name = 'InviteShareRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<InviteShareRouteArgs>(
        orElse: () => const InviteShareRouteArgs(),
      );
      return _i14.InviteShareRoutePage(key: args.key, invite: args.invite);
    },
  );
}

class InviteShareRouteArgs {
  const InviteShareRouteArgs({this.key, this.invite});

  final _i65.Key? key;

  final _i67.InviteModel? invite;

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
/// [_i15.LandlordHomeRoutePage]
class LandlordHomeRoute extends _i64.PageRouteInfo<void> {
  const LandlordHomeRoute({List<_i64.PageRouteInfo>? children})
      : super(LandlordHomeRoute.name, initialChildren: children);

  static const String name = 'LandlordHomeRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i15.LandlordHomeRoutePage();
    },
  );
}

/// generated route for
/// [_i16.LocationPermissionRoutePage]
class LocationPermissionRoute
    extends _i64.PageRouteInfo<LocationPermissionRouteArgs> {
  LocationPermissionRoute({
    _i65.Key? key,
    _i68.LocationPermissionState? initialState,
    bool allowContinueWithoutLocation = true,
    _i65.ValueChanged<_i69.LocationPermissionGateResult>? onResult,
    List<_i64.PageRouteInfo>? children,
  }) : super(
          LocationPermissionRoute.name,
          args: LocationPermissionRouteArgs(
            key: key,
            initialState: initialState,
            allowContinueWithoutLocation: allowContinueWithoutLocation,
            onResult: onResult,
          ),
          initialChildren: children,
        );

  static const String name = 'LocationPermissionRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<LocationPermissionRouteArgs>(
        orElse: () => const LocationPermissionRouteArgs(),
      );
      return _i16.LocationPermissionRoutePage(
        key: args.key,
        initialState: args.initialState,
        allowContinueWithoutLocation: args.allowContinueWithoutLocation,
        onResult: args.onResult,
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
  });

  final _i65.Key? key;

  final _i68.LocationPermissionState? initialState;

  final bool allowContinueWithoutLocation;

  final _i65.ValueChanged<_i69.LocationPermissionGateResult>? onResult;

  @override
  String toString() {
    return 'LocationPermissionRouteArgs{key: $key, initialState: $initialState, allowContinueWithoutLocation: $allowContinueWithoutLocation, onResult: $onResult}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LocationPermissionRouteArgs) return false;
    return key == other.key &&
        initialState == other.initialState &&
        allowContinueWithoutLocation == other.allowContinueWithoutLocation &&
        onResult == other.onResult;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      initialState.hashCode ^
      allowContinueWithoutLocation.hashCode ^
      onResult.hashCode;
}

/// generated route for
/// [_i17.PartnerDetailRoute]
class PartnerDetailRoute extends _i64.PageRouteInfo<PartnerDetailRouteArgs> {
  PartnerDetailRoute({
    _i65.Key? key,
    required String slug,
    List<_i64.PageRouteInfo>? children,
  }) : super(
          PartnerDetailRoute.name,
          args: PartnerDetailRouteArgs(key: key, slug: slug),
          rawPathParams: {'slug': slug},
          initialChildren: children,
        );

  static const String name = 'PartnerDetailRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<PartnerDetailRouteArgs>(
        orElse: () =>
            PartnerDetailRouteArgs(slug: pathParams.getString('slug')),
      );
      return _i17.PartnerDetailRoute(key: args.key, slug: args.slug);
    },
  );
}

class PartnerDetailRouteArgs {
  const PartnerDetailRouteArgs({this.key, required this.slug});

  final _i65.Key? key;

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
/// [_i18.PoiDetailsRoutePage]
class PoiDetailsRoute extends _i64.PageRouteInfo<PoiDetailsRouteArgs> {
  PoiDetailsRoute({
    _i65.Key? key,
    String? poi,
    String? stack,
    List<_i64.PageRouteInfo>? children,
  }) : super(
          PoiDetailsRoute.name,
          args: PoiDetailsRouteArgs(key: key, poi: poi, stack: stack),
          rawQueryParams: {'poi': poi, 'stack': stack},
          initialChildren: children,
        );

  static const String name = 'PoiDetailsRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final queryParams = data.queryParams;
      final args = data.argsAs<PoiDetailsRouteArgs>(
        orElse: () => PoiDetailsRouteArgs(
          poi: queryParams.optString('poi'),
          stack: queryParams.optString('stack'),
        ),
      );
      return _i18.PoiDetailsRoutePage(
        key: args.key,
        poi: args.poi,
        stack: args.stack,
      );
    },
  );
}

class PoiDetailsRouteArgs {
  const PoiDetailsRouteArgs({this.key, this.poi, this.stack});

  final _i65.Key? key;

  final String? poi;

  final String? stack;

  @override
  String toString() {
    return 'PoiDetailsRouteArgs{key: $key, poi: $poi, stack: $stack}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PoiDetailsRouteArgs) return false;
    return key == other.key && poi == other.poi && stack == other.stack;
  }

  @override
  int get hashCode => key.hashCode ^ poi.hashCode ^ stack.hashCode;
}

/// generated route for
/// [_i19.ProfileRoutePage]
class ProfileRoute extends _i64.PageRouteInfo<void> {
  const ProfileRoute({List<_i64.PageRouteInfo>? children})
      : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i19.ProfileRoutePage();
    },
  );
}

/// generated route for
/// [_i20.RecoveryPasswordRoutePage]
class RecoveryPasswordRoute
    extends _i64.PageRouteInfo<RecoveryPasswordRouteArgs> {
  RecoveryPasswordRoute({
    _i65.Key? key,
    String? initialEmmail,
    List<_i64.PageRouteInfo>? children,
  }) : super(
          RecoveryPasswordRoute.name,
          args: RecoveryPasswordRouteArgs(
            key: key,
            initialEmmail: initialEmmail,
          ),
          initialChildren: children,
        );

  static const String name = 'RecoveryPasswordRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RecoveryPasswordRouteArgs>(
        orElse: () => const RecoveryPasswordRouteArgs(),
      );
      return _i20.RecoveryPasswordRoutePage(
        key: args.key,
        initialEmmail: args.initialEmmail,
      );
    },
  );
}

class RecoveryPasswordRouteArgs {
  const RecoveryPasswordRouteArgs({this.key, this.initialEmmail});

  final _i65.Key? key;

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
/// [_i21.TenantAdminAccountCreateRoutePage]
class TenantAdminAccountCreateRoute extends _i64.PageRouteInfo<void> {
  const TenantAdminAccountCreateRoute({List<_i64.PageRouteInfo>? children})
      : super(TenantAdminAccountCreateRoute.name, initialChildren: children);

  static const String name = 'TenantAdminAccountCreateRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i21.TenantAdminAccountCreateRoutePage();
    },
  );
}

/// generated route for
/// [_i22.TenantAdminAccountDetailRoutePage]
class TenantAdminAccountDetailRoute
    extends _i64.PageRouteInfo<TenantAdminAccountDetailRouteArgs> {
  TenantAdminAccountDetailRoute({
    _i65.Key? key,
    required String accountSlug,
    List<_i64.PageRouteInfo>? children,
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

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminAccountDetailRouteArgs>(
        orElse: () => TenantAdminAccountDetailRouteArgs(
          accountSlug: pathParams.getString('accountSlug'),
        ),
      );
      return _i22.TenantAdminAccountDetailRoutePage(
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

  final _i65.Key? key;

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
/// [_i23.TenantAdminAccountProfileCreateRoutePage]
class TenantAdminAccountProfileCreateRoute
    extends _i64.PageRouteInfo<TenantAdminAccountProfileCreateRouteArgs> {
  TenantAdminAccountProfileCreateRoute({
    _i65.Key? key,
    required String accountSlug,
    List<_i64.PageRouteInfo>? children,
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

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminAccountProfileCreateRouteArgs>(
        orElse: () => TenantAdminAccountProfileCreateRouteArgs(
          accountSlug: pathParams.getString('accountSlug'),
        ),
      );
      return _i23.TenantAdminAccountProfileCreateRoutePage(
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

  final _i65.Key? key;

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
/// [_i24.TenantAdminAccountProfileEditRoutePage]
class TenantAdminAccountProfileEditRoute
    extends _i64.PageRouteInfo<TenantAdminAccountProfileEditRouteArgs> {
  TenantAdminAccountProfileEditRoute({
    _i65.Key? key,
    required String accountSlug,
    required String accountProfileId,
    List<_i64.PageRouteInfo>? children,
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

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminAccountProfileEditRouteArgs>(
        orElse: () => TenantAdminAccountProfileEditRouteArgs(
          accountSlug: pathParams.getString('accountSlug'),
          accountProfileId: pathParams.getString('accountProfileId'),
        ),
      );
      return _i24.TenantAdminAccountProfileEditRoutePage(
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

  final _i65.Key? key;

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
/// [_i25.TenantAdminAccountsListRoutePage]
class TenantAdminAccountsListRoute extends _i64.PageRouteInfo<void> {
  const TenantAdminAccountsListRoute({List<_i64.PageRouteInfo>? children})
      : super(TenantAdminAccountsListRoute.name, initialChildren: children);

  static const String name = 'TenantAdminAccountsListRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i25.TenantAdminAccountsListRoutePage();
    },
  );
}

/// generated route for
/// [_i26.TenantAdminDashboardRoutePage]
class TenantAdminDashboardRoute extends _i64.PageRouteInfo<void> {
  const TenantAdminDashboardRoute({List<_i64.PageRouteInfo>? children})
      : super(TenantAdminDashboardRoute.name, initialChildren: children);

  static const String name = 'TenantAdminDashboardRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i26.TenantAdminDashboardRoutePage();
    },
  );
}

/// generated route for
/// [_i27.TenantAdminEventCreateRoutePage]
class TenantAdminEventCreateRoute extends _i64.PageRouteInfo<void> {
  const TenantAdminEventCreateRoute({List<_i64.PageRouteInfo>? children})
      : super(TenantAdminEventCreateRoute.name, initialChildren: children);

  static const String name = 'TenantAdminEventCreateRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i27.TenantAdminEventCreateRoutePage();
    },
  );
}

/// generated route for
/// [_i28.TenantAdminEventEditRoutePage]
class TenantAdminEventEditRoute
    extends _i64.PageRouteInfo<TenantAdminEventEditRouteArgs> {
  TenantAdminEventEditRoute({
    _i70.TenantAdminEvent? event,
    _i65.Key? key,
    List<_i64.PageRouteInfo>? children,
  }) : super(
          TenantAdminEventEditRoute.name,
          args: TenantAdminEventEditRouteArgs(event: event, key: key),
          initialChildren: children,
        );

  static const String name = 'TenantAdminEventEditRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TenantAdminEventEditRouteArgs>(
        orElse: () => const TenantAdminEventEditRouteArgs(),
      );
      return _i28.TenantAdminEventEditRoutePage(
        event: args.event,
        key: args.key,
      );
    },
  );
}

class TenantAdminEventEditRouteArgs {
  const TenantAdminEventEditRouteArgs({this.event, this.key});

  final _i70.TenantAdminEvent? event;

  final _i65.Key? key;

  @override
  String toString() {
    return 'TenantAdminEventEditRouteArgs{event: $event, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TenantAdminEventEditRouteArgs) return false;
    return event == other.event && key == other.key;
  }

  @override
  int get hashCode => event.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i29.TenantAdminEventTypeCreateRoutePage]
class TenantAdminEventTypeCreateRoute extends _i64.PageRouteInfo<void> {
  const TenantAdminEventTypeCreateRoute({List<_i64.PageRouteInfo>? children})
      : super(TenantAdminEventTypeCreateRoute.name, initialChildren: children);

  static const String name = 'TenantAdminEventTypeCreateRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i29.TenantAdminEventTypeCreateRoutePage();
    },
  );
}

/// generated route for
/// [_i30.TenantAdminEventTypeEditRoutePage]
class TenantAdminEventTypeEditRoute
    extends _i64.PageRouteInfo<TenantAdminEventTypeEditRouteArgs> {
  TenantAdminEventTypeEditRoute({
    _i70.TenantAdminEventType? type,
    _i65.Key? key,
    List<_i64.PageRouteInfo>? children,
  }) : super(
          TenantAdminEventTypeEditRoute.name,
          args: TenantAdminEventTypeEditRouteArgs(type: type, key: key),
          initialChildren: children,
        );

  static const String name = 'TenantAdminEventTypeEditRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TenantAdminEventTypeEditRouteArgs>(
        orElse: () => const TenantAdminEventTypeEditRouteArgs(),
      );
      return _i30.TenantAdminEventTypeEditRoutePage(
        type: args.type,
        key: args.key,
      );
    },
  );
}

class TenantAdminEventTypeEditRouteArgs {
  const TenantAdminEventTypeEditRouteArgs({this.type, this.key});

  final _i70.TenantAdminEventType? type;

  final _i65.Key? key;

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
/// [_i31.TenantAdminEventTypesRoutePage]
class TenantAdminEventTypesRoute extends _i64.PageRouteInfo<void> {
  const TenantAdminEventTypesRoute({List<_i64.PageRouteInfo>? children})
      : super(TenantAdminEventTypesRoute.name, initialChildren: children);

  static const String name = 'TenantAdminEventTypesRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i31.TenantAdminEventTypesRoutePage();
    },
  );
}

/// generated route for
/// [_i32.TenantAdminEventsRoutePage]
class TenantAdminEventsRoute extends _i64.PageRouteInfo<void> {
  const TenantAdminEventsRoute({List<_i64.PageRouteInfo>? children})
      : super(TenantAdminEventsRoute.name, initialChildren: children);

  static const String name = 'TenantAdminEventsRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i32.TenantAdminEventsRoutePage();
    },
  );
}

/// generated route for
/// [_i33.TenantAdminLocationPickerRoutePage]
class TenantAdminLocationPickerRoute
    extends _i64.PageRouteInfo<TenantAdminLocationPickerRouteArgs> {
  TenantAdminLocationPickerRoute({
    _i65.Key? key,
    _i71.TenantAdminLocation? initialLocation,
    List<_i64.PageRouteInfo>? children,
  }) : super(
          TenantAdminLocationPickerRoute.name,
          args: TenantAdminLocationPickerRouteArgs(
            key: key,
            initialLocation: initialLocation,
          ),
          initialChildren: children,
        );

  static const String name = 'TenantAdminLocationPickerRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TenantAdminLocationPickerRouteArgs>(
        orElse: () => const TenantAdminLocationPickerRouteArgs(),
      );
      return _i33.TenantAdminLocationPickerRoutePage(
        key: args.key,
        initialLocation: args.initialLocation,
      );
    },
  );
}

class TenantAdminLocationPickerRouteArgs {
  const TenantAdminLocationPickerRouteArgs({this.key, this.initialLocation});

  final _i65.Key? key;

  final _i71.TenantAdminLocation? initialLocation;

  @override
  String toString() {
    return 'TenantAdminLocationPickerRouteArgs{key: $key, initialLocation: $initialLocation}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TenantAdminLocationPickerRouteArgs) return false;
    return key == other.key && initialLocation == other.initialLocation;
  }

  @override
  int get hashCode => key.hashCode ^ initialLocation.hashCode;
}

/// generated route for
/// [_i34.TenantAdminOrganizationCreateRoutePage]
class TenantAdminOrganizationCreateRoute extends _i64.PageRouteInfo<void> {
  const TenantAdminOrganizationCreateRoute({List<_i64.PageRouteInfo>? children})
      : super(TenantAdminOrganizationCreateRoute.name,
            initialChildren: children);

  static const String name = 'TenantAdminOrganizationCreateRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i34.TenantAdminOrganizationCreateRoutePage();
    },
  );
}

/// generated route for
/// [_i35.TenantAdminOrganizationDetailRoutePage]
class TenantAdminOrganizationDetailRoute
    extends _i64.PageRouteInfo<TenantAdminOrganizationDetailRouteArgs> {
  TenantAdminOrganizationDetailRoute({
    _i65.Key? key,
    required String organizationId,
    List<_i64.PageRouteInfo>? children,
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

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminOrganizationDetailRouteArgs>(
        orElse: () => TenantAdminOrganizationDetailRouteArgs(
          organizationId: pathParams.getString('organizationId'),
        ),
      );
      return _i35.TenantAdminOrganizationDetailRoutePage(
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

  final _i65.Key? key;

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
/// [_i36.TenantAdminOrganizationsListRoutePage]
class TenantAdminOrganizationsListRoute extends _i64.PageRouteInfo<void> {
  const TenantAdminOrganizationsListRoute({List<_i64.PageRouteInfo>? children})
      : super(TenantAdminOrganizationsListRoute.name,
            initialChildren: children);

  static const String name = 'TenantAdminOrganizationsListRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i36.TenantAdminOrganizationsListRoutePage();
    },
  );
}

/// generated route for
/// [_i37.TenantAdminProfileTypeCreateRoutePage]
class TenantAdminProfileTypeCreateRoute extends _i64.PageRouteInfo<void> {
  const TenantAdminProfileTypeCreateRoute({List<_i64.PageRouteInfo>? children})
      : super(TenantAdminProfileTypeCreateRoute.name,
            initialChildren: children);

  static const String name = 'TenantAdminProfileTypeCreateRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i37.TenantAdminProfileTypeCreateRoutePage();
    },
  );
}

/// generated route for
/// [_i38.TenantAdminProfileTypeDetailRoutePage]
class TenantAdminProfileTypeDetailRoute
    extends _i64.PageRouteInfo<TenantAdminProfileTypeDetailRouteArgs> {
  TenantAdminProfileTypeDetailRoute({
    _i65.Key? key,
    required String profileType,
    List<_i64.PageRouteInfo>? children,
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

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminProfileTypeDetailRouteArgs>(
        orElse: () => TenantAdminProfileTypeDetailRouteArgs(
          profileType: pathParams.getString('profileType'),
        ),
      );
      return _i38.TenantAdminProfileTypeDetailRoutePage(
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

  final _i65.Key? key;

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
/// [_i39.TenantAdminProfileTypeEditRoutePage]
class TenantAdminProfileTypeEditRoute
    extends _i64.PageRouteInfo<TenantAdminProfileTypeEditRouteArgs> {
  TenantAdminProfileTypeEditRoute({
    _i65.Key? key,
    required String profileType,
    List<_i64.PageRouteInfo>? children,
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

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminProfileTypeEditRouteArgs>(
        orElse: () => TenantAdminProfileTypeEditRouteArgs(
          profileType: pathParams.getString('profileType'),
        ),
      );
      return _i39.TenantAdminProfileTypeEditRoutePage(
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

  final _i65.Key? key;

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
/// [_i40.TenantAdminProfileTypesListRoutePage]
class TenantAdminProfileTypesListRoute extends _i64.PageRouteInfo<void> {
  const TenantAdminProfileTypesListRoute({List<_i64.PageRouteInfo>? children})
      : super(TenantAdminProfileTypesListRoute.name, initialChildren: children);

  static const String name = 'TenantAdminProfileTypesListRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i40.TenantAdminProfileTypesListRoutePage();
    },
  );
}

/// generated route for
/// [_i41.TenantAdminSettingsEnvironmentSnapshotRoutePage]
class TenantAdminSettingsEnvironmentSnapshotRoute
    extends _i64.PageRouteInfo<void> {
  const TenantAdminSettingsEnvironmentSnapshotRoute({
    List<_i64.PageRouteInfo>? children,
  }) : super(
          TenantAdminSettingsEnvironmentSnapshotRoute.name,
          initialChildren: children,
        );

  static const String name = 'TenantAdminSettingsEnvironmentSnapshotRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i41.TenantAdminSettingsEnvironmentSnapshotRoutePage();
    },
  );
}

/// generated route for
/// [_i42.TenantAdminSettingsLocalPreferencesRoutePage]
class TenantAdminSettingsLocalPreferencesRoute
    extends _i64.PageRouteInfo<void> {
  const TenantAdminSettingsLocalPreferencesRoute({
    List<_i64.PageRouteInfo>? children,
  }) : super(
          TenantAdminSettingsLocalPreferencesRoute.name,
          initialChildren: children,
        );

  static const String name = 'TenantAdminSettingsLocalPreferencesRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i42.TenantAdminSettingsLocalPreferencesRoutePage();
    },
  );
}

/// generated route for
/// [_i43.TenantAdminSettingsRoutePage]
class TenantAdminSettingsRoute extends _i64.PageRouteInfo<void> {
  const TenantAdminSettingsRoute({List<_i64.PageRouteInfo>? children})
      : super(TenantAdminSettingsRoute.name, initialChildren: children);

  static const String name = 'TenantAdminSettingsRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i43.TenantAdminSettingsRoutePage();
    },
  );
}

/// generated route for
/// [_i44.TenantAdminSettingsTechnicalIntegrationsRoutePage]
class TenantAdminSettingsTechnicalIntegrationsRoute extends _i64
    .PageRouteInfo<TenantAdminSettingsTechnicalIntegrationsRouteArgs> {
  TenantAdminSettingsTechnicalIntegrationsRoute({
    _i65.Key? key,
    _i72.TenantAdminSettingsIntegrationSection initialSection =
        _i72.TenantAdminSettingsIntegrationSection.firebase,
    List<_i64.PageRouteInfo>? children,
  }) : super(
          TenantAdminSettingsTechnicalIntegrationsRoute.name,
          args: TenantAdminSettingsTechnicalIntegrationsRouteArgs(
            key: key,
            initialSection: initialSection,
          ),
          initialChildren: children,
        );

  static const String name = 'TenantAdminSettingsTechnicalIntegrationsRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final args =
          data.argsAs<TenantAdminSettingsTechnicalIntegrationsRouteArgs>(
        orElse: () => const TenantAdminSettingsTechnicalIntegrationsRouteArgs(),
      );
      return _i44.TenantAdminSettingsTechnicalIntegrationsRoutePage(
        key: args.key,
        initialSection: args.initialSection,
      );
    },
  );
}

class TenantAdminSettingsTechnicalIntegrationsRouteArgs {
  const TenantAdminSettingsTechnicalIntegrationsRouteArgs({
    this.key,
    this.initialSection = _i72.TenantAdminSettingsIntegrationSection.firebase,
  });

  final _i65.Key? key;

  final _i72.TenantAdminSettingsIntegrationSection initialSection;

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
/// [_i45.TenantAdminSettingsVisualIdentityRoutePage]
class TenantAdminSettingsVisualIdentityRoute extends _i64.PageRouteInfo<void> {
  const TenantAdminSettingsVisualIdentityRoute({
    List<_i64.PageRouteInfo>? children,
  }) : super(
          TenantAdminSettingsVisualIdentityRoute.name,
          initialChildren: children,
        );

  static const String name = 'TenantAdminSettingsVisualIdentityRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i45.TenantAdminSettingsVisualIdentityRoutePage();
    },
  );
}

/// generated route for
/// [_i46.TenantAdminShellRoutePage]
class TenantAdminShellRoute extends _i64.PageRouteInfo<void> {
  const TenantAdminShellRoute({List<_i64.PageRouteInfo>? children})
      : super(TenantAdminShellRoute.name, initialChildren: children);

  static const String name = 'TenantAdminShellRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i46.TenantAdminShellRoutePage();
    },
  );
}

/// generated route for
/// [_i47.TenantAdminStaticAssetCreateRoutePage]
class TenantAdminStaticAssetCreateRoute extends _i64.PageRouteInfo<void> {
  const TenantAdminStaticAssetCreateRoute({List<_i64.PageRouteInfo>? children})
      : super(TenantAdminStaticAssetCreateRoute.name,
            initialChildren: children);

  static const String name = 'TenantAdminStaticAssetCreateRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i47.TenantAdminStaticAssetCreateRoutePage();
    },
  );
}

/// generated route for
/// [_i48.TenantAdminStaticAssetDetailRoutePage]
class TenantAdminStaticAssetDetailRoute
    extends _i64.PageRouteInfo<TenantAdminStaticAssetDetailRouteArgs> {
  TenantAdminStaticAssetDetailRoute({
    _i65.Key? key,
    required String assetId,
    List<_i64.PageRouteInfo>? children,
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

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminStaticAssetDetailRouteArgs>(
        orElse: () => TenantAdminStaticAssetDetailRouteArgs(
          assetId: pathParams.getString('assetId'),
        ),
      );
      return _i48.TenantAdminStaticAssetDetailRoutePage(
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

  final _i65.Key? key;

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
/// [_i49.TenantAdminStaticAssetEditRoutePage]
class TenantAdminStaticAssetEditRoute
    extends _i64.PageRouteInfo<TenantAdminStaticAssetEditRouteArgs> {
  TenantAdminStaticAssetEditRoute({
    _i65.Key? key,
    required String assetId,
    List<_i64.PageRouteInfo>? children,
  }) : super(
          TenantAdminStaticAssetEditRoute.name,
          args: TenantAdminStaticAssetEditRouteArgs(key: key, assetId: assetId),
          rawPathParams: {'assetId': assetId},
          initialChildren: children,
        );

  static const String name = 'TenantAdminStaticAssetEditRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminStaticAssetEditRouteArgs>(
        orElse: () => TenantAdminStaticAssetEditRouteArgs(
          assetId: pathParams.getString('assetId'),
        ),
      );
      return _i49.TenantAdminStaticAssetEditRoutePage(
        key: args.key,
        assetId: args.assetId,
      );
    },
  );
}

class TenantAdminStaticAssetEditRouteArgs {
  const TenantAdminStaticAssetEditRouteArgs({this.key, required this.assetId});

  final _i65.Key? key;

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
/// [_i50.TenantAdminStaticAssetsListRoutePage]
class TenantAdminStaticAssetsListRoute extends _i64.PageRouteInfo<void> {
  const TenantAdminStaticAssetsListRoute({List<_i64.PageRouteInfo>? children})
      : super(TenantAdminStaticAssetsListRoute.name, initialChildren: children);

  static const String name = 'TenantAdminStaticAssetsListRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i50.TenantAdminStaticAssetsListRoutePage();
    },
  );
}

/// generated route for
/// [_i51.TenantAdminStaticProfileTypeCreateRoutePage]
class TenantAdminStaticProfileTypeCreateRoute extends _i64.PageRouteInfo<void> {
  const TenantAdminStaticProfileTypeCreateRoute({
    List<_i64.PageRouteInfo>? children,
  }) : super(
          TenantAdminStaticProfileTypeCreateRoute.name,
          initialChildren: children,
        );

  static const String name = 'TenantAdminStaticProfileTypeCreateRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i51.TenantAdminStaticProfileTypeCreateRoutePage();
    },
  );
}

/// generated route for
/// [_i52.TenantAdminStaticProfileTypeDetailRoutePage]
class TenantAdminStaticProfileTypeDetailRoute
    extends _i64.PageRouteInfo<TenantAdminStaticProfileTypeDetailRouteArgs> {
  TenantAdminStaticProfileTypeDetailRoute({
    _i65.Key? key,
    required String profileType,
    List<_i64.PageRouteInfo>? children,
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

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminStaticProfileTypeDetailRouteArgs>(
        orElse: () => TenantAdminStaticProfileTypeDetailRouteArgs(
          profileType: pathParams.getString('profileType'),
        ),
      );
      return _i52.TenantAdminStaticProfileTypeDetailRoutePage(
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

  final _i65.Key? key;

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
/// [_i53.TenantAdminStaticProfileTypeEditRoutePage]
class TenantAdminStaticProfileTypeEditRoute
    extends _i64.PageRouteInfo<TenantAdminStaticProfileTypeEditRouteArgs> {
  TenantAdminStaticProfileTypeEditRoute({
    _i65.Key? key,
    required String profileType,
    List<_i64.PageRouteInfo>? children,
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

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminStaticProfileTypeEditRouteArgs>(
        orElse: () => TenantAdminStaticProfileTypeEditRouteArgs(
          profileType: pathParams.getString('profileType'),
        ),
      );
      return _i53.TenantAdminStaticProfileTypeEditRoutePage(
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

  final _i65.Key? key;

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
/// [_i54.TenantAdminStaticProfileTypesListRoutePage]
class TenantAdminStaticProfileTypesListRoute extends _i64.PageRouteInfo<void> {
  const TenantAdminStaticProfileTypesListRoute({
    List<_i64.PageRouteInfo>? children,
  }) : super(
          TenantAdminStaticProfileTypesListRoute.name,
          initialChildren: children,
        );

  static const String name = 'TenantAdminStaticProfileTypesListRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i54.TenantAdminStaticProfileTypesListRoutePage();
    },
  );
}

/// generated route for
/// [_i55.TenantAdminTaxonomiesListRoutePage]
class TenantAdminTaxonomiesListRoute extends _i64.PageRouteInfo<void> {
  const TenantAdminTaxonomiesListRoute({List<_i64.PageRouteInfo>? children})
      : super(TenantAdminTaxonomiesListRoute.name, initialChildren: children);

  static const String name = 'TenantAdminTaxonomiesListRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i55.TenantAdminTaxonomiesListRoutePage();
    },
  );
}

/// generated route for
/// [_i56.TenantAdminTaxonomyCreateRoutePage]
class TenantAdminTaxonomyCreateRoute extends _i64.PageRouteInfo<void> {
  const TenantAdminTaxonomyCreateRoute({List<_i64.PageRouteInfo>? children})
      : super(TenantAdminTaxonomyCreateRoute.name, initialChildren: children);

  static const String name = 'TenantAdminTaxonomyCreateRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i56.TenantAdminTaxonomyCreateRoutePage();
    },
  );
}

/// generated route for
/// [_i57.TenantAdminTaxonomyEditRoutePage]
class TenantAdminTaxonomyEditRoute
    extends _i64.PageRouteInfo<TenantAdminTaxonomyEditRouteArgs> {
  TenantAdminTaxonomyEditRoute({
    _i65.Key? key,
    required String taxonomyId,
    List<_i64.PageRouteInfo>? children,
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

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminTaxonomyEditRouteArgs>(
        orElse: () => TenantAdminTaxonomyEditRouteArgs(
          taxonomyId: pathParams.getString('taxonomyId'),
        ),
      );
      return _i57.TenantAdminTaxonomyEditRoutePage(
        key: args.key,
        taxonomyId: args.taxonomyId,
      );
    },
  );
}

class TenantAdminTaxonomyEditRouteArgs {
  const TenantAdminTaxonomyEditRouteArgs({this.key, required this.taxonomyId});

  final _i65.Key? key;

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
/// [_i58.TenantAdminTaxonomyTermCreateRoutePage]
class TenantAdminTaxonomyTermCreateRoute
    extends _i64.PageRouteInfo<TenantAdminTaxonomyTermCreateRouteArgs> {
  TenantAdminTaxonomyTermCreateRoute({
    _i65.Key? key,
    required String taxonomyId,
    List<_i64.PageRouteInfo>? children,
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

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminTaxonomyTermCreateRouteArgs>(
        orElse: () => TenantAdminTaxonomyTermCreateRouteArgs(
          taxonomyId: pathParams.getString('taxonomyId'),
        ),
      );
      return _i58.TenantAdminTaxonomyTermCreateRoutePage(
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

  final _i65.Key? key;

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
/// [_i59.TenantAdminTaxonomyTermDetailRoutePage]
class TenantAdminTaxonomyTermDetailRoute
    extends _i64.PageRouteInfo<TenantAdminTaxonomyTermDetailRouteArgs> {
  TenantAdminTaxonomyTermDetailRoute({
    _i65.Key? key,
    required String taxonomyId,
    required String termId,
    List<_i64.PageRouteInfo>? children,
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

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminTaxonomyTermDetailRouteArgs>(
        orElse: () => TenantAdminTaxonomyTermDetailRouteArgs(
          taxonomyId: pathParams.getString('taxonomyId'),
          termId: pathParams.getString('termId'),
        ),
      );
      return _i59.TenantAdminTaxonomyTermDetailRoutePage(
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

  final _i65.Key? key;

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
/// [_i60.TenantAdminTaxonomyTermEditRoutePage]
class TenantAdminTaxonomyTermEditRoute
    extends _i64.PageRouteInfo<TenantAdminTaxonomyTermEditRouteArgs> {
  TenantAdminTaxonomyTermEditRoute({
    _i65.Key? key,
    required String taxonomyId,
    required String termId,
    List<_i64.PageRouteInfo>? children,
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

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminTaxonomyTermEditRouteArgs>(
        orElse: () => TenantAdminTaxonomyTermEditRouteArgs(
          taxonomyId: pathParams.getString('taxonomyId'),
          termId: pathParams.getString('termId'),
        ),
      );
      return _i60.TenantAdminTaxonomyTermEditRoutePage(
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

  final _i65.Key? key;

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
/// [_i61.TenantAdminTaxonomyTermsRoutePage]
class TenantAdminTaxonomyTermsRoute
    extends _i64.PageRouteInfo<TenantAdminTaxonomyTermsRouteArgs> {
  TenantAdminTaxonomyTermsRoute({
    _i65.Key? key,
    required String taxonomyId,
    List<_i64.PageRouteInfo>? children,
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

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminTaxonomyTermsRouteArgs>(
        orElse: () => TenantAdminTaxonomyTermsRouteArgs(
          taxonomyId: pathParams.getString('taxonomyId'),
        ),
      );
      return _i61.TenantAdminTaxonomyTermsRoutePage(
        key: args.key,
        taxonomyId: args.taxonomyId,
      );
    },
  );
}

class TenantAdminTaxonomyTermsRouteArgs {
  const TenantAdminTaxonomyTermsRouteArgs({this.key, required this.taxonomyId});

  final _i65.Key? key;

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
/// [_i62.TenantHomeRoutePage]
class TenantHomeRoute extends _i64.PageRouteInfo<void> {
  const TenantHomeRoute({List<_i64.PageRouteInfo>? children})
      : super(TenantHomeRoute.name, initialChildren: children);

  static const String name = 'TenantHomeRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i62.TenantHomeRoutePage();
    },
  );
}

/// generated route for
/// [_i63.TenantPrivacyPolicyRoutePage]
class TenantPrivacyPolicyRoute extends _i64.PageRouteInfo<void> {
  const TenantPrivacyPolicyRoute({List<_i64.PageRouteInfo>? children})
      : super(TenantPrivacyPolicyRoute.name, initialChildren: children);

  static const String name = 'TenantPrivacyPolicyRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i63.TenantPrivacyPolicyRoutePage();
    },
  );
}
