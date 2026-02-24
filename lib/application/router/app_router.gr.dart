// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i56;
import 'package:belluga_now/application/router/guards/location_permission_state.dart'
    as _i60;
import 'package:belluga_now/domain/invites/invite_model.dart' as _i59;
import 'package:belluga_now/domain/map/city_poi_model.dart' as _i61;
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart'
    as _i62;
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart'
    as _i63;
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart'
    as _i65;
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart'
    as _i66;
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart'
    as _i67;
import 'package:belluga_now/presentation/account_workspace/routes/account_workspace_home_route.dart'
    as _i1;
import 'package:belluga_now/presentation/account_workspace/routes/account_workspace_scoped_route.dart'
    as _i2;
import 'package:belluga_now/presentation/landlord_area/home/routes/landlord_home_route.dart'
    as _i13;
import 'package:belluga_now/presentation/shared/auth/routes/auth_create_new_password_route.dart'
    as _i3;
import 'package:belluga_now/presentation/shared/auth/routes/auth_login_route.dart'
    as _i4;
import 'package:belluga_now/presentation/shared/auth/routes/recovery_password_route.dart'
    as _i19;
import 'package:belluga_now/presentation/shared/init/routes/init_route.dart'
    as _i10;
import 'package:belluga_now/presentation/shared/location_permission/routes/location_not_live_route.dart'
    as _i14;
import 'package:belluga_now/presentation/shared/location_permission/routes/location_permission_route.dart'
    as _i15;
import 'package:belluga_now/presentation/tenant_admin/account_profiles/routes/tenant_admin_account_profile_create_route.dart'
    as _i22;
import 'package:belluga_now/presentation/tenant_admin/account_profiles/routes/tenant_admin_account_profile_edit_route.dart'
    as _i23;
import 'package:belluga_now/presentation/tenant_admin/accounts/routes/tenant_admin_account_create_route.dart'
    as _i20;
import 'package:belluga_now/presentation/tenant_admin/accounts/routes/tenant_admin_account_detail_route.dart'
    as _i21;
import 'package:belluga_now/presentation/tenant_admin/accounts/routes/tenant_admin_accounts_list_route.dart'
    as _i24;
import 'package:belluga_now/presentation/tenant_admin/accounts/screens/tenant_admin_location_picker_screen.dart'
    as _i27;
import 'package:belluga_now/presentation/tenant_admin/events/routes/tenant_admin_events_route.dart'
    as _i26;
import 'package:belluga_now/presentation/tenant_admin/organizations/routes/tenant_admin_organization_create_route.dart'
    as _i28;
import 'package:belluga_now/presentation/tenant_admin/organizations/routes/tenant_admin_organization_detail_route.dart'
    as _i29;
import 'package:belluga_now/presentation/tenant_admin/organizations/routes/tenant_admin_organizations_list_route.dart'
    as _i30;
import 'package:belluga_now/presentation/tenant_admin/profile_types/routes/tenant_admin_profile_type_create_route.dart'
    as _i31;
import 'package:belluga_now/presentation/tenant_admin/profile_types/routes/tenant_admin_profile_type_detail_route.dart'
    as _i32;
import 'package:belluga_now/presentation/tenant_admin/profile_types/routes/tenant_admin_profile_type_edit_route.dart'
    as _i33;
import 'package:belluga_now/presentation/tenant_admin/profile_types/routes/tenant_admin_profile_types_list_route.dart'
    as _i34;
import 'package:belluga_now/presentation/tenant_admin/settings/models/tenant_admin_settings_integration_section.dart'
    as _i64;
import 'package:belluga_now/presentation/tenant_admin/settings/routes/tenant_admin_settings_environment_snapshot_route.dart'
    as _i35;
import 'package:belluga_now/presentation/tenant_admin/settings/routes/tenant_admin_settings_local_preferences_route.dart'
    as _i36;
import 'package:belluga_now/presentation/tenant_admin/settings/routes/tenant_admin_settings_route.dart'
    as _i37;
import 'package:belluga_now/presentation/tenant_admin/settings/routes/tenant_admin_settings_technical_integrations_route.dart'
    as _i38;
import 'package:belluga_now/presentation/tenant_admin/settings/routes/tenant_admin_settings_visual_identity_route.dart'
    as _i39;
import 'package:belluga_now/presentation/tenant_admin/shell/routes/tenant_admin_dashboard_route.dart'
    as _i25;
import 'package:belluga_now/presentation/tenant_admin/shell/routes/tenant_admin_shell_route.dart'
    as _i40;
import 'package:belluga_now/presentation/tenant_admin/static_assets/routes/tenant_admin_static_asset_create_route.dart'
    as _i41;
import 'package:belluga_now/presentation/tenant_admin/static_assets/routes/tenant_admin_static_asset_detail_route.dart'
    as _i42;
import 'package:belluga_now/presentation/tenant_admin/static_assets/routes/tenant_admin_static_asset_edit_route.dart'
    as _i43;
import 'package:belluga_now/presentation/tenant_admin/static_assets/routes/tenant_admin_static_assets_list_route.dart'
    as _i44;
import 'package:belluga_now/presentation/tenant_admin/static_profile_types/routes/tenant_admin_static_profile_type_create_route.dart'
    as _i45;
import 'package:belluga_now/presentation/tenant_admin/static_profile_types/routes/tenant_admin_static_profile_type_detail_route.dart'
    as _i46;
import 'package:belluga_now/presentation/tenant_admin/static_profile_types/routes/tenant_admin_static_profile_type_edit_route.dart'
    as _i47;
import 'package:belluga_now/presentation/tenant_admin/static_profile_types/routes/tenant_admin_static_profile_types_list_route.dart'
    as _i48;
import 'package:belluga_now/presentation/tenant_admin/taxonomies/routes/tenant_admin_taxonomies_list_route.dart'
    as _i49;
import 'package:belluga_now/presentation/tenant_admin/taxonomies/routes/tenant_admin_taxonomy_form_route.dart'
    as _i50;
import 'package:belluga_now/presentation/tenant_admin/taxonomies/routes/tenant_admin_taxonomy_term_detail_route.dart'
    as _i52;
import 'package:belluga_now/presentation/tenant_admin/taxonomies/routes/tenant_admin_taxonomy_term_form_route.dart'
    as _i51;
import 'package:belluga_now/presentation/tenant_admin/taxonomies/routes/tenant_admin_taxonomy_terms_route.dart'
    as _i53;
import 'package:belluga_now/presentation/tenant_public/discovery/routes/discovery_route.dart'
    as _i6;
import 'package:belluga_now/presentation/tenant_public/home/routes/tenant_home_route.dart'
    as _i54;
import 'package:belluga_now/presentation/tenant_public/invites/routes/invite_flow_route.dart'
    as _i11;
import 'package:belluga_now/presentation/tenant_public/invites/routes/invite_share_route.dart'
    as _i12;
import 'package:belluga_now/presentation/tenant_public/map/routes/city_map_route.dart'
    as _i5;
import 'package:belluga_now/presentation/tenant_public/map/routes/poi_details_route.dart'
    as _i17;
import 'package:belluga_now/presentation/tenant_public/menu/routes/tenant_menu_route.dart'
    as _i55;
import 'package:belluga_now/presentation/tenant_public/partners/routes/partner_detail_route.dart'
    as _i16;
import 'package:belluga_now/presentation/tenant_public/profile/routes/profile_route.dart'
    as _i18;
import 'package:belluga_now/presentation/tenant_public/schedule/routes/event_detail_route.dart'
    as _i7;
import 'package:belluga_now/presentation/tenant_public/schedule/routes/event_search_route.dart'
    as _i8;
import 'package:belluga_now/presentation/tenant_public/schedule/routes/immersive_event_detail_route.dart'
    as _i9;
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/models/invite_filter.dart'
    as _i58;
import 'package:flutter/material.dart' as _i57;

/// generated route for
/// [_i1.AccountWorkspaceHomeRoutePage]
class AccountWorkspaceHomeRoute extends _i56.PageRouteInfo<void> {
  const AccountWorkspaceHomeRoute({List<_i56.PageRouteInfo>? children})
      : super(AccountWorkspaceHomeRoute.name, initialChildren: children);

  static const String name = 'AccountWorkspaceHomeRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      return const _i1.AccountWorkspaceHomeRoutePage();
    },
  );
}

/// generated route for
/// [_i2.AccountWorkspaceScopedRoutePage]
class AccountWorkspaceScopedRoute
    extends _i56.PageRouteInfo<AccountWorkspaceScopedRouteArgs> {
  AccountWorkspaceScopedRoute({
    required String accountSlug,
    _i57.Key? key,
    List<_i56.PageRouteInfo>? children,
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

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<AccountWorkspaceScopedRouteArgs>(
        orElse: () => AccountWorkspaceScopedRouteArgs(
          accountSlug: pathParams.getString('accountSlug'),
        ),
      );
      return _i2.AccountWorkspaceScopedRoutePage(
        accountSlug: args.accountSlug,
        key: args.key,
      );
    },
  );
}

class AccountWorkspaceScopedRouteArgs {
  const AccountWorkspaceScopedRouteArgs({required this.accountSlug, this.key});

  final String accountSlug;

  final _i57.Key? key;

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
/// [_i3.AuthCreateNewPasswordRoutePage]
class AuthCreateNewPasswordRoute extends _i56.PageRouteInfo<void> {
  const AuthCreateNewPasswordRoute({List<_i56.PageRouteInfo>? children})
      : super(AuthCreateNewPasswordRoute.name, initialChildren: children);

  static const String name = 'AuthCreateNewPasswordRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      return const _i3.AuthCreateNewPasswordRoutePage();
    },
  );
}

/// generated route for
/// [_i4.AuthLoginRoutePage]
class AuthLoginRoute extends _i56.PageRouteInfo<void> {
  const AuthLoginRoute({List<_i56.PageRouteInfo>? children})
      : super(AuthLoginRoute.name, initialChildren: children);

  static const String name = 'AuthLoginRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      return const _i4.AuthLoginRoutePage();
    },
  );
}

/// generated route for
/// [_i5.CityMapRoutePage]
class CityMapRoute extends _i56.PageRouteInfo<void> {
  const CityMapRoute({List<_i56.PageRouteInfo>? children})
      : super(CityMapRoute.name, initialChildren: children);

  static const String name = 'CityMapRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      return const _i5.CityMapRoutePage();
    },
  );
}

/// generated route for
/// [_i6.DiscoveryRoute]
class DiscoveryRoute extends _i56.PageRouteInfo<void> {
  const DiscoveryRoute({List<_i56.PageRouteInfo>? children})
      : super(DiscoveryRoute.name, initialChildren: children);

  static const String name = 'DiscoveryRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      return const _i6.DiscoveryRoute();
    },
  );
}

/// generated route for
/// [_i7.EventDetailRoutePage]
class EventDetailRoute extends _i56.PageRouteInfo<EventDetailRouteArgs> {
  EventDetailRoute({
    _i57.Key? key,
    required String slug,
    List<_i56.PageRouteInfo>? children,
  }) : super(
          EventDetailRoute.name,
          args: EventDetailRouteArgs(key: key, slug: slug),
          rawPathParams: {'slug': slug},
          initialChildren: children,
        );

  static const String name = 'EventDetailRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<EventDetailRouteArgs>(
        orElse: () => EventDetailRouteArgs(slug: pathParams.getString('slug')),
      );
      return _i7.EventDetailRoutePage(key: args.key, slug: args.slug);
    },
  );
}

class EventDetailRouteArgs {
  const EventDetailRouteArgs({this.key, required this.slug});

  final _i57.Key? key;

  final String slug;

  @override
  String toString() {
    return 'EventDetailRouteArgs{key: $key, slug: $slug}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EventDetailRouteArgs) return false;
    return key == other.key && slug == other.slug;
  }

  @override
  int get hashCode => key.hashCode ^ slug.hashCode;
}

/// generated route for
/// [_i8.EventSearchRoute]
class EventSearchRoute extends _i56.PageRouteInfo<EventSearchRouteArgs> {
  EventSearchRoute({
    _i57.Key? key,
    bool startSearchActive = false,
    String? initialSearchQuery,
    _i58.InviteFilter inviteFilter = _i58.InviteFilter.none,
    bool startWithHistory = false,
    List<_i56.PageRouteInfo>? children,
  }) : super(
          EventSearchRoute.name,
          args: EventSearchRouteArgs(
            key: key,
            startSearchActive: startSearchActive,
            initialSearchQuery: initialSearchQuery,
            inviteFilter: inviteFilter,
            startWithHistory: startWithHistory,
          ),
          initialChildren: children,
        );

  static const String name = 'EventSearchRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<EventSearchRouteArgs>(
        orElse: () => const EventSearchRouteArgs(),
      );
      return _i8.EventSearchRoute(
        key: args.key,
        startSearchActive: args.startSearchActive,
        initialSearchQuery: args.initialSearchQuery,
        inviteFilter: args.inviteFilter,
        startWithHistory: args.startWithHistory,
      );
    },
  );
}

class EventSearchRouteArgs {
  const EventSearchRouteArgs({
    this.key,
    this.startSearchActive = false,
    this.initialSearchQuery,
    this.inviteFilter = _i58.InviteFilter.none,
    this.startWithHistory = false,
  });

  final _i57.Key? key;

  final bool startSearchActive;

  final String? initialSearchQuery;

  final _i58.InviteFilter inviteFilter;

  final bool startWithHistory;

  @override
  String toString() {
    return 'EventSearchRouteArgs{key: $key, startSearchActive: $startSearchActive, initialSearchQuery: $initialSearchQuery, inviteFilter: $inviteFilter, startWithHistory: $startWithHistory}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EventSearchRouteArgs) return false;
    return key == other.key &&
        startSearchActive == other.startSearchActive &&
        initialSearchQuery == other.initialSearchQuery &&
        inviteFilter == other.inviteFilter &&
        startWithHistory == other.startWithHistory;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      startSearchActive.hashCode ^
      initialSearchQuery.hashCode ^
      inviteFilter.hashCode ^
      startWithHistory.hashCode;
}

/// generated route for
/// [_i9.ImmersiveEventDetailRoutePage]
class ImmersiveEventDetailRoute
    extends _i56.PageRouteInfo<ImmersiveEventDetailRouteArgs> {
  ImmersiveEventDetailRoute({
    _i57.Key? key,
    required String eventSlug,
    List<_i56.PageRouteInfo>? children,
  }) : super(
          ImmersiveEventDetailRoute.name,
          args: ImmersiveEventDetailRouteArgs(key: key, eventSlug: eventSlug),
          rawPathParams: {'slug': eventSlug},
          initialChildren: children,
        );

  static const String name = 'ImmersiveEventDetailRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<ImmersiveEventDetailRouteArgs>(
        orElse: () => ImmersiveEventDetailRouteArgs(
          eventSlug: pathParams.getString('slug'),
        ),
      );
      return _i9.ImmersiveEventDetailRoutePage(
        key: args.key,
        eventSlug: args.eventSlug,
      );
    },
  );
}

class ImmersiveEventDetailRouteArgs {
  const ImmersiveEventDetailRouteArgs({this.key, required this.eventSlug});

  final _i57.Key? key;

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
/// [_i10.InitRoutePage]
class InitRoute extends _i56.PageRouteInfo<void> {
  const InitRoute({List<_i56.PageRouteInfo>? children})
      : super(InitRoute.name, initialChildren: children);

  static const String name = 'InitRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      return const _i10.InitRoutePage();
    },
  );
}

/// generated route for
/// [_i11.InviteFlowRoutePage]
class InviteFlowRoute extends _i56.PageRouteInfo<void> {
  const InviteFlowRoute({List<_i56.PageRouteInfo>? children})
      : super(InviteFlowRoute.name, initialChildren: children);

  static const String name = 'InviteFlowRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      return const _i11.InviteFlowRoutePage();
    },
  );
}

/// generated route for
/// [_i12.InviteShareRoutePage]
class InviteShareRoute extends _i56.PageRouteInfo<InviteShareRouteArgs> {
  InviteShareRoute({
    _i57.Key? key,
    required _i59.InviteModel invite,
    List<_i56.PageRouteInfo>? children,
  }) : super(
          InviteShareRoute.name,
          args: InviteShareRouteArgs(key: key, invite: invite),
          initialChildren: children,
        );

  static const String name = 'InviteShareRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<InviteShareRouteArgs>();
      return _i12.InviteShareRoutePage(key: args.key, invite: args.invite);
    },
  );
}

class InviteShareRouteArgs {
  const InviteShareRouteArgs({this.key, required this.invite});

  final _i57.Key? key;

  final _i59.InviteModel invite;

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
/// [_i13.LandlordHomeRoutePage]
class LandlordHomeRoute extends _i56.PageRouteInfo<void> {
  const LandlordHomeRoute({List<_i56.PageRouteInfo>? children})
      : super(LandlordHomeRoute.name, initialChildren: children);

  static const String name = 'LandlordHomeRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      return const _i13.LandlordHomeRoutePage();
    },
  );
}

/// generated route for
/// [_i14.LocationNotLiveRoutePage]
class LocationNotLiveRoute
    extends _i56.PageRouteInfo<LocationNotLiveRouteArgs> {
  LocationNotLiveRoute({
    _i57.Key? key,
    required _i60.LocationPermissionState blockerState,
    String? addressLabel,
    DateTime? capturedAt,
    List<_i56.PageRouteInfo>? children,
  }) : super(
          LocationNotLiveRoute.name,
          args: LocationNotLiveRouteArgs(
            key: key,
            blockerState: blockerState,
            addressLabel: addressLabel,
            capturedAt: capturedAt,
          ),
          initialChildren: children,
        );

  static const String name = 'LocationNotLiveRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<LocationNotLiveRouteArgs>();
      return _i14.LocationNotLiveRoutePage(
        key: args.key,
        blockerState: args.blockerState,
        addressLabel: args.addressLabel,
        capturedAt: args.capturedAt,
      );
    },
  );
}

class LocationNotLiveRouteArgs {
  const LocationNotLiveRouteArgs({
    this.key,
    required this.blockerState,
    this.addressLabel,
    this.capturedAt,
  });

  final _i57.Key? key;

  final _i60.LocationPermissionState blockerState;

  final String? addressLabel;

  final DateTime? capturedAt;

  @override
  String toString() {
    return 'LocationNotLiveRouteArgs{key: $key, blockerState: $blockerState, addressLabel: $addressLabel, capturedAt: $capturedAt}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LocationNotLiveRouteArgs) return false;
    return key == other.key &&
        blockerState == other.blockerState &&
        addressLabel == other.addressLabel &&
        capturedAt == other.capturedAt;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      blockerState.hashCode ^
      addressLabel.hashCode ^
      capturedAt.hashCode;
}

/// generated route for
/// [_i15.LocationPermissionRoutePage]
class LocationPermissionRoute
    extends _i56.PageRouteInfo<LocationPermissionRouteArgs> {
  LocationPermissionRoute({
    _i57.Key? key,
    required _i60.LocationPermissionState initialState,
    List<_i56.PageRouteInfo>? children,
  }) : super(
          LocationPermissionRoute.name,
          args: LocationPermissionRouteArgs(
            key: key,
            initialState: initialState,
          ),
          initialChildren: children,
        );

  static const String name = 'LocationPermissionRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<LocationPermissionRouteArgs>();
      return _i15.LocationPermissionRoutePage(
        key: args.key,
        initialState: args.initialState,
      );
    },
  );
}

class LocationPermissionRouteArgs {
  const LocationPermissionRouteArgs({this.key, required this.initialState});

  final _i57.Key? key;

  final _i60.LocationPermissionState initialState;

  @override
  String toString() {
    return 'LocationPermissionRouteArgs{key: $key, initialState: $initialState}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LocationPermissionRouteArgs) return false;
    return key == other.key && initialState == other.initialState;
  }

  @override
  int get hashCode => key.hashCode ^ initialState.hashCode;
}

/// generated route for
/// [_i16.PartnerDetailRoute]
class PartnerDetailRoute extends _i56.PageRouteInfo<PartnerDetailRouteArgs> {
  PartnerDetailRoute({
    _i57.Key? key,
    required String slug,
    List<_i56.PageRouteInfo>? children,
  }) : super(
          PartnerDetailRoute.name,
          args: PartnerDetailRouteArgs(key: key, slug: slug),
          rawPathParams: {'slug': slug},
          initialChildren: children,
        );

  static const String name = 'PartnerDetailRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<PartnerDetailRouteArgs>(
        orElse: () =>
            PartnerDetailRouteArgs(slug: pathParams.getString('slug')),
      );
      return _i16.PartnerDetailRoute(key: args.key, slug: args.slug);
    },
  );
}

class PartnerDetailRouteArgs {
  const PartnerDetailRouteArgs({this.key, required this.slug});

  final _i57.Key? key;

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
/// [_i17.PoiDetailsRoutePage]
class PoiDetailsRoute extends _i56.PageRouteInfo<PoiDetailsRouteArgs> {
  PoiDetailsRoute({
    _i57.Key? key,
    required _i61.CityPoiModel poi,
    List<_i56.PageRouteInfo>? children,
  }) : super(
          PoiDetailsRoute.name,
          args: PoiDetailsRouteArgs(key: key, poi: poi),
          initialChildren: children,
        );

  static const String name = 'PoiDetailsRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PoiDetailsRouteArgs>();
      return _i17.PoiDetailsRoutePage(key: args.key, poi: args.poi);
    },
  );
}

class PoiDetailsRouteArgs {
  const PoiDetailsRouteArgs({this.key, required this.poi});

  final _i57.Key? key;

  final _i61.CityPoiModel poi;

  @override
  String toString() {
    return 'PoiDetailsRouteArgs{key: $key, poi: $poi}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PoiDetailsRouteArgs) return false;
    return key == other.key && poi == other.poi;
  }

  @override
  int get hashCode => key.hashCode ^ poi.hashCode;
}

/// generated route for
/// [_i18.ProfileRoutePage]
class ProfileRoute extends _i56.PageRouteInfo<void> {
  const ProfileRoute({List<_i56.PageRouteInfo>? children})
      : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      return const _i18.ProfileRoutePage();
    },
  );
}

/// generated route for
/// [_i19.RecoveryPasswordRoutePage]
class RecoveryPasswordRoute
    extends _i56.PageRouteInfo<RecoveryPasswordRouteArgs> {
  RecoveryPasswordRoute({
    _i57.Key? key,
    String? initialEmmail,
    List<_i56.PageRouteInfo>? children,
  }) : super(
          RecoveryPasswordRoute.name,
          args: RecoveryPasswordRouteArgs(
            key: key,
            initialEmmail: initialEmmail,
          ),
          initialChildren: children,
        );

  static const String name = 'RecoveryPasswordRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RecoveryPasswordRouteArgs>(
        orElse: () => const RecoveryPasswordRouteArgs(),
      );
      return _i19.RecoveryPasswordRoutePage(
        key: args.key,
        initialEmmail: args.initialEmmail,
      );
    },
  );
}

class RecoveryPasswordRouteArgs {
  const RecoveryPasswordRouteArgs({this.key, this.initialEmmail});

  final _i57.Key? key;

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
/// [_i20.TenantAdminAccountCreateRoutePage]
class TenantAdminAccountCreateRoute extends _i56.PageRouteInfo<void> {
  const TenantAdminAccountCreateRoute({List<_i56.PageRouteInfo>? children})
      : super(TenantAdminAccountCreateRoute.name, initialChildren: children);

  static const String name = 'TenantAdminAccountCreateRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      return const _i20.TenantAdminAccountCreateRoutePage();
    },
  );
}

/// generated route for
/// [_i21.TenantAdminAccountDetailRoutePage]
class TenantAdminAccountDetailRoute
    extends _i56.PageRouteInfo<TenantAdminAccountDetailRouteArgs> {
  TenantAdminAccountDetailRoute({
    _i57.Key? key,
    required String accountSlug,
    List<_i56.PageRouteInfo>? children,
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

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminAccountDetailRouteArgs>(
        orElse: () => TenantAdminAccountDetailRouteArgs(
          accountSlug: pathParams.getString('accountSlug'),
        ),
      );
      return _i21.TenantAdminAccountDetailRoutePage(
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

  final _i57.Key? key;

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
/// [_i22.TenantAdminAccountProfileCreateRoutePage]
class TenantAdminAccountProfileCreateRoute
    extends _i56.PageRouteInfo<TenantAdminAccountProfileCreateRouteArgs> {
  TenantAdminAccountProfileCreateRoute({
    _i57.Key? key,
    required String accountSlug,
    List<_i56.PageRouteInfo>? children,
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

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminAccountProfileCreateRouteArgs>(
        orElse: () => TenantAdminAccountProfileCreateRouteArgs(
          accountSlug: pathParams.getString('accountSlug'),
        ),
      );
      return _i22.TenantAdminAccountProfileCreateRoutePage(
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

  final _i57.Key? key;

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
/// [_i23.TenantAdminAccountProfileEditRoutePage]
class TenantAdminAccountProfileEditRoute
    extends _i56.PageRouteInfo<TenantAdminAccountProfileEditRouteArgs> {
  TenantAdminAccountProfileEditRoute({
    _i57.Key? key,
    required String accountSlug,
    required String accountProfileId,
    List<_i56.PageRouteInfo>? children,
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

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminAccountProfileEditRouteArgs>(
        orElse: () => TenantAdminAccountProfileEditRouteArgs(
          accountSlug: pathParams.getString('accountSlug'),
          accountProfileId: pathParams.getString('accountProfileId'),
        ),
      );
      return _i23.TenantAdminAccountProfileEditRoutePage(
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

  final _i57.Key? key;

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
/// [_i24.TenantAdminAccountsListRoutePage]
class TenantAdminAccountsListRoute extends _i56.PageRouteInfo<void> {
  const TenantAdminAccountsListRoute({List<_i56.PageRouteInfo>? children})
      : super(TenantAdminAccountsListRoute.name, initialChildren: children);

  static const String name = 'TenantAdminAccountsListRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      return const _i24.TenantAdminAccountsListRoutePage();
    },
  );
}

/// generated route for
/// [_i25.TenantAdminDashboardRoutePage]
class TenantAdminDashboardRoute extends _i56.PageRouteInfo<void> {
  const TenantAdminDashboardRoute({List<_i56.PageRouteInfo>? children})
      : super(TenantAdminDashboardRoute.name, initialChildren: children);

  static const String name = 'TenantAdminDashboardRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      return const _i25.TenantAdminDashboardRoutePage();
    },
  );
}

/// generated route for
/// [_i26.TenantAdminEventsRoutePage]
class TenantAdminEventsRoute extends _i56.PageRouteInfo<void> {
  const TenantAdminEventsRoute({List<_i56.PageRouteInfo>? children})
      : super(TenantAdminEventsRoute.name, initialChildren: children);

  static const String name = 'TenantAdminEventsRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      return const _i26.TenantAdminEventsRoutePage();
    },
  );
}

/// generated route for
/// [_i27.TenantAdminLocationPickerScreen]
class TenantAdminLocationPickerRoute
    extends _i56.PageRouteInfo<TenantAdminLocationPickerRouteArgs> {
  TenantAdminLocationPickerRoute({
    _i57.Key? key,
    _i62.TenantAdminLocation? initialLocation,
    List<_i56.PageRouteInfo>? children,
  }) : super(
          TenantAdminLocationPickerRoute.name,
          args: TenantAdminLocationPickerRouteArgs(
            key: key,
            initialLocation: initialLocation,
          ),
          initialChildren: children,
        );

  static const String name = 'TenantAdminLocationPickerRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TenantAdminLocationPickerRouteArgs>(
        orElse: () => const TenantAdminLocationPickerRouteArgs(),
      );
      return _i27.TenantAdminLocationPickerScreen(
        key: args.key,
        initialLocation: args.initialLocation,
      );
    },
  );
}

class TenantAdminLocationPickerRouteArgs {
  const TenantAdminLocationPickerRouteArgs({this.key, this.initialLocation});

  final _i57.Key? key;

  final _i62.TenantAdminLocation? initialLocation;

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
/// [_i28.TenantAdminOrganizationCreateRoutePage]
class TenantAdminOrganizationCreateRoute extends _i56.PageRouteInfo<void> {
  const TenantAdminOrganizationCreateRoute({List<_i56.PageRouteInfo>? children})
      : super(TenantAdminOrganizationCreateRoute.name,
            initialChildren: children);

  static const String name = 'TenantAdminOrganizationCreateRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      return const _i28.TenantAdminOrganizationCreateRoutePage();
    },
  );
}

/// generated route for
/// [_i29.TenantAdminOrganizationDetailRoutePage]
class TenantAdminOrganizationDetailRoute
    extends _i56.PageRouteInfo<TenantAdminOrganizationDetailRouteArgs> {
  TenantAdminOrganizationDetailRoute({
    _i57.Key? key,
    required String organizationId,
    List<_i56.PageRouteInfo>? children,
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

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminOrganizationDetailRouteArgs>(
        orElse: () => TenantAdminOrganizationDetailRouteArgs(
          organizationId: pathParams.getString('organizationId'),
        ),
      );
      return _i29.TenantAdminOrganizationDetailRoutePage(
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

  final _i57.Key? key;

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
/// [_i30.TenantAdminOrganizationsListRoutePage]
class TenantAdminOrganizationsListRoute extends _i56.PageRouteInfo<void> {
  const TenantAdminOrganizationsListRoute({List<_i56.PageRouteInfo>? children})
      : super(TenantAdminOrganizationsListRoute.name,
            initialChildren: children);

  static const String name = 'TenantAdminOrganizationsListRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      return const _i30.TenantAdminOrganizationsListRoutePage();
    },
  );
}

/// generated route for
/// [_i31.TenantAdminProfileTypeCreateRoutePage]
class TenantAdminProfileTypeCreateRoute extends _i56.PageRouteInfo<void> {
  const TenantAdminProfileTypeCreateRoute({List<_i56.PageRouteInfo>? children})
      : super(TenantAdminProfileTypeCreateRoute.name,
            initialChildren: children);

  static const String name = 'TenantAdminProfileTypeCreateRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      return const _i31.TenantAdminProfileTypeCreateRoutePage();
    },
  );
}

/// generated route for
/// [_i32.TenantAdminProfileTypeDetailRoutePage]
class TenantAdminProfileTypeDetailRoute
    extends _i56.PageRouteInfo<TenantAdminProfileTypeDetailRouteArgs> {
  TenantAdminProfileTypeDetailRoute({
    _i57.Key? key,
    required String profileType,
    required _i63.TenantAdminProfileTypeDefinition definition,
    List<_i56.PageRouteInfo>? children,
  }) : super(
          TenantAdminProfileTypeDetailRoute.name,
          args: TenantAdminProfileTypeDetailRouteArgs(
            key: key,
            profileType: profileType,
            definition: definition,
          ),
          rawPathParams: {'profileType': profileType},
          initialChildren: children,
        );

  static const String name = 'TenantAdminProfileTypeDetailRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TenantAdminProfileTypeDetailRouteArgs>();
      return _i32.TenantAdminProfileTypeDetailRoutePage(
        key: args.key,
        profileType: args.profileType,
        definition: args.definition,
      );
    },
  );
}

class TenantAdminProfileTypeDetailRouteArgs {
  const TenantAdminProfileTypeDetailRouteArgs({
    this.key,
    required this.profileType,
    required this.definition,
  });

  final _i57.Key? key;

  final String profileType;

  final _i63.TenantAdminProfileTypeDefinition definition;

  @override
  String toString() {
    return 'TenantAdminProfileTypeDetailRouteArgs{key: $key, profileType: $profileType, definition: $definition}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TenantAdminProfileTypeDetailRouteArgs) return false;
    return key == other.key &&
        profileType == other.profileType &&
        definition == other.definition;
  }

  @override
  int get hashCode => key.hashCode ^ profileType.hashCode ^ definition.hashCode;
}

/// generated route for
/// [_i33.TenantAdminProfileTypeEditRoutePage]
class TenantAdminProfileTypeEditRoute
    extends _i56.PageRouteInfo<TenantAdminProfileTypeEditRouteArgs> {
  TenantAdminProfileTypeEditRoute({
    _i57.Key? key,
    required String profileType,
    required _i63.TenantAdminProfileTypeDefinition definition,
    List<_i56.PageRouteInfo>? children,
  }) : super(
          TenantAdminProfileTypeEditRoute.name,
          args: TenantAdminProfileTypeEditRouteArgs(
            key: key,
            profileType: profileType,
            definition: definition,
          ),
          rawPathParams: {'profileType': profileType},
          initialChildren: children,
        );

  static const String name = 'TenantAdminProfileTypeEditRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TenantAdminProfileTypeEditRouteArgs>();
      return _i33.TenantAdminProfileTypeEditRoutePage(
        key: args.key,
        profileType: args.profileType,
        definition: args.definition,
      );
    },
  );
}

class TenantAdminProfileTypeEditRouteArgs {
  const TenantAdminProfileTypeEditRouteArgs({
    this.key,
    required this.profileType,
    required this.definition,
  });

  final _i57.Key? key;

  final String profileType;

  final _i63.TenantAdminProfileTypeDefinition definition;

  @override
  String toString() {
    return 'TenantAdminProfileTypeEditRouteArgs{key: $key, profileType: $profileType, definition: $definition}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TenantAdminProfileTypeEditRouteArgs) return false;
    return key == other.key &&
        profileType == other.profileType &&
        definition == other.definition;
  }

  @override
  int get hashCode => key.hashCode ^ profileType.hashCode ^ definition.hashCode;
}

/// generated route for
/// [_i34.TenantAdminProfileTypesListRoutePage]
class TenantAdminProfileTypesListRoute extends _i56.PageRouteInfo<void> {
  const TenantAdminProfileTypesListRoute({List<_i56.PageRouteInfo>? children})
      : super(TenantAdminProfileTypesListRoute.name, initialChildren: children);

  static const String name = 'TenantAdminProfileTypesListRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      return const _i34.TenantAdminProfileTypesListRoutePage();
    },
  );
}

/// generated route for
/// [_i35.TenantAdminSettingsEnvironmentSnapshotRoutePage]
class TenantAdminSettingsEnvironmentSnapshotRoute
    extends _i56.PageRouteInfo<void> {
  const TenantAdminSettingsEnvironmentSnapshotRoute({
    List<_i56.PageRouteInfo>? children,
  }) : super(
          TenantAdminSettingsEnvironmentSnapshotRoute.name,
          initialChildren: children,
        );

  static const String name = 'TenantAdminSettingsEnvironmentSnapshotRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      return const _i35.TenantAdminSettingsEnvironmentSnapshotRoutePage();
    },
  );
}

/// generated route for
/// [_i36.TenantAdminSettingsLocalPreferencesRoutePage]
class TenantAdminSettingsLocalPreferencesRoute
    extends _i56.PageRouteInfo<void> {
  const TenantAdminSettingsLocalPreferencesRoute({
    List<_i56.PageRouteInfo>? children,
  }) : super(
          TenantAdminSettingsLocalPreferencesRoute.name,
          initialChildren: children,
        );

  static const String name = 'TenantAdminSettingsLocalPreferencesRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      return const _i36.TenantAdminSettingsLocalPreferencesRoutePage();
    },
  );
}

/// generated route for
/// [_i37.TenantAdminSettingsRoutePage]
class TenantAdminSettingsRoute extends _i56.PageRouteInfo<void> {
  const TenantAdminSettingsRoute({List<_i56.PageRouteInfo>? children})
      : super(TenantAdminSettingsRoute.name, initialChildren: children);

  static const String name = 'TenantAdminSettingsRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      return const _i37.TenantAdminSettingsRoutePage();
    },
  );
}

/// generated route for
/// [_i38.TenantAdminSettingsTechnicalIntegrationsRoutePage]
class TenantAdminSettingsTechnicalIntegrationsRoute extends _i56
    .PageRouteInfo<TenantAdminSettingsTechnicalIntegrationsRouteArgs> {
  TenantAdminSettingsTechnicalIntegrationsRoute({
    _i57.Key? key,
    _i64.TenantAdminSettingsIntegrationSection initialSection =
        _i64.TenantAdminSettingsIntegrationSection.firebase,
    List<_i56.PageRouteInfo>? children,
  }) : super(
          TenantAdminSettingsTechnicalIntegrationsRoute.name,
          args: TenantAdminSettingsTechnicalIntegrationsRouteArgs(
            key: key,
            initialSection: initialSection,
          ),
          initialChildren: children,
        );

  static const String name = 'TenantAdminSettingsTechnicalIntegrationsRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      final args =
          data.argsAs<TenantAdminSettingsTechnicalIntegrationsRouteArgs>(
        orElse: () => const TenantAdminSettingsTechnicalIntegrationsRouteArgs(),
      );
      return _i38.TenantAdminSettingsTechnicalIntegrationsRoutePage(
        key: args.key,
        initialSection: args.initialSection,
      );
    },
  );
}

class TenantAdminSettingsTechnicalIntegrationsRouteArgs {
  const TenantAdminSettingsTechnicalIntegrationsRouteArgs({
    this.key,
    this.initialSection = _i64.TenantAdminSettingsIntegrationSection.firebase,
  });

  final _i57.Key? key;

  final _i64.TenantAdminSettingsIntegrationSection initialSection;

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
/// [_i39.TenantAdminSettingsVisualIdentityRoutePage]
class TenantAdminSettingsVisualIdentityRoute extends _i56.PageRouteInfo<void> {
  const TenantAdminSettingsVisualIdentityRoute({
    List<_i56.PageRouteInfo>? children,
  }) : super(
          TenantAdminSettingsVisualIdentityRoute.name,
          initialChildren: children,
        );

  static const String name = 'TenantAdminSettingsVisualIdentityRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      return const _i39.TenantAdminSettingsVisualIdentityRoutePage();
    },
  );
}

/// generated route for
/// [_i40.TenantAdminShellRoutePage]
class TenantAdminShellRoute extends _i56.PageRouteInfo<void> {
  const TenantAdminShellRoute({List<_i56.PageRouteInfo>? children})
      : super(TenantAdminShellRoute.name, initialChildren: children);

  static const String name = 'TenantAdminShellRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      return const _i40.TenantAdminShellRoutePage();
    },
  );
}

/// generated route for
/// [_i41.TenantAdminStaticAssetCreateRoutePage]
class TenantAdminStaticAssetCreateRoute extends _i56.PageRouteInfo<void> {
  const TenantAdminStaticAssetCreateRoute({List<_i56.PageRouteInfo>? children})
      : super(TenantAdminStaticAssetCreateRoute.name,
            initialChildren: children);

  static const String name = 'TenantAdminStaticAssetCreateRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      return const _i41.TenantAdminStaticAssetCreateRoutePage();
    },
  );
}

/// generated route for
/// [_i42.TenantAdminStaticAssetDetailRoutePage]
class TenantAdminStaticAssetDetailRoute
    extends _i56.PageRouteInfo<TenantAdminStaticAssetDetailRouteArgs> {
  TenantAdminStaticAssetDetailRoute({
    _i57.Key? key,
    required String assetId,
    List<_i56.PageRouteInfo>? children,
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

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminStaticAssetDetailRouteArgs>(
        orElse: () => TenantAdminStaticAssetDetailRouteArgs(
          assetId: pathParams.getString('assetId'),
        ),
      );
      return _i42.TenantAdminStaticAssetDetailRoutePage(
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

  final _i57.Key? key;

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
/// [_i43.TenantAdminStaticAssetEditRoutePage]
class TenantAdminStaticAssetEditRoute
    extends _i56.PageRouteInfo<TenantAdminStaticAssetEditRouteArgs> {
  TenantAdminStaticAssetEditRoute({
    _i57.Key? key,
    required String assetId,
    List<_i56.PageRouteInfo>? children,
  }) : super(
          TenantAdminStaticAssetEditRoute.name,
          args: TenantAdminStaticAssetEditRouteArgs(key: key, assetId: assetId),
          rawPathParams: {'assetId': assetId},
          initialChildren: children,
        );

  static const String name = 'TenantAdminStaticAssetEditRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminStaticAssetEditRouteArgs>(
        orElse: () => TenantAdminStaticAssetEditRouteArgs(
          assetId: pathParams.getString('assetId'),
        ),
      );
      return _i43.TenantAdminStaticAssetEditRoutePage(
        key: args.key,
        assetId: args.assetId,
      );
    },
  );
}

class TenantAdminStaticAssetEditRouteArgs {
  const TenantAdminStaticAssetEditRouteArgs({this.key, required this.assetId});

  final _i57.Key? key;

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
/// [_i44.TenantAdminStaticAssetsListRoutePage]
class TenantAdminStaticAssetsListRoute extends _i56.PageRouteInfo<void> {
  const TenantAdminStaticAssetsListRoute({List<_i56.PageRouteInfo>? children})
      : super(TenantAdminStaticAssetsListRoute.name, initialChildren: children);

  static const String name = 'TenantAdminStaticAssetsListRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      return const _i44.TenantAdminStaticAssetsListRoutePage();
    },
  );
}

/// generated route for
/// [_i45.TenantAdminStaticProfileTypeCreateRoutePage]
class TenantAdminStaticProfileTypeCreateRoute extends _i56.PageRouteInfo<void> {
  const TenantAdminStaticProfileTypeCreateRoute({
    List<_i56.PageRouteInfo>? children,
  }) : super(
          TenantAdminStaticProfileTypeCreateRoute.name,
          initialChildren: children,
        );

  static const String name = 'TenantAdminStaticProfileTypeCreateRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      return const _i45.TenantAdminStaticProfileTypeCreateRoutePage();
    },
  );
}

/// generated route for
/// [_i46.TenantAdminStaticProfileTypeDetailRoutePage]
class TenantAdminStaticProfileTypeDetailRoute
    extends _i56.PageRouteInfo<TenantAdminStaticProfileTypeDetailRouteArgs> {
  TenantAdminStaticProfileTypeDetailRoute({
    _i57.Key? key,
    required String profileType,
    required _i65.TenantAdminStaticProfileTypeDefinition definition,
    List<_i56.PageRouteInfo>? children,
  }) : super(
          TenantAdminStaticProfileTypeDetailRoute.name,
          args: TenantAdminStaticProfileTypeDetailRouteArgs(
            key: key,
            profileType: profileType,
            definition: definition,
          ),
          rawPathParams: {'profileType': profileType},
          initialChildren: children,
        );

  static const String name = 'TenantAdminStaticProfileTypeDetailRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TenantAdminStaticProfileTypeDetailRouteArgs>();
      return _i46.TenantAdminStaticProfileTypeDetailRoutePage(
        key: args.key,
        profileType: args.profileType,
        definition: args.definition,
      );
    },
  );
}

class TenantAdminStaticProfileTypeDetailRouteArgs {
  const TenantAdminStaticProfileTypeDetailRouteArgs({
    this.key,
    required this.profileType,
    required this.definition,
  });

  final _i57.Key? key;

  final String profileType;

  final _i65.TenantAdminStaticProfileTypeDefinition definition;

  @override
  String toString() {
    return 'TenantAdminStaticProfileTypeDetailRouteArgs{key: $key, profileType: $profileType, definition: $definition}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TenantAdminStaticProfileTypeDetailRouteArgs) return false;
    return key == other.key &&
        profileType == other.profileType &&
        definition == other.definition;
  }

  @override
  int get hashCode => key.hashCode ^ profileType.hashCode ^ definition.hashCode;
}

/// generated route for
/// [_i47.TenantAdminStaticProfileTypeEditRoutePage]
class TenantAdminStaticProfileTypeEditRoute
    extends _i56.PageRouteInfo<TenantAdminStaticProfileTypeEditRouteArgs> {
  TenantAdminStaticProfileTypeEditRoute({
    _i57.Key? key,
    required String profileType,
    required _i65.TenantAdminStaticProfileTypeDefinition definition,
    List<_i56.PageRouteInfo>? children,
  }) : super(
          TenantAdminStaticProfileTypeEditRoute.name,
          args: TenantAdminStaticProfileTypeEditRouteArgs(
            key: key,
            profileType: profileType,
            definition: definition,
          ),
          rawPathParams: {'profileType': profileType},
          initialChildren: children,
        );

  static const String name = 'TenantAdminStaticProfileTypeEditRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TenantAdminStaticProfileTypeEditRouteArgs>();
      return _i47.TenantAdminStaticProfileTypeEditRoutePage(
        key: args.key,
        profileType: args.profileType,
        definition: args.definition,
      );
    },
  );
}

class TenantAdminStaticProfileTypeEditRouteArgs {
  const TenantAdminStaticProfileTypeEditRouteArgs({
    this.key,
    required this.profileType,
    required this.definition,
  });

  final _i57.Key? key;

  final String profileType;

  final _i65.TenantAdminStaticProfileTypeDefinition definition;

  @override
  String toString() {
    return 'TenantAdminStaticProfileTypeEditRouteArgs{key: $key, profileType: $profileType, definition: $definition}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TenantAdminStaticProfileTypeEditRouteArgs) return false;
    return key == other.key &&
        profileType == other.profileType &&
        definition == other.definition;
  }

  @override
  int get hashCode => key.hashCode ^ profileType.hashCode ^ definition.hashCode;
}

/// generated route for
/// [_i48.TenantAdminStaticProfileTypesListRoutePage]
class TenantAdminStaticProfileTypesListRoute extends _i56.PageRouteInfo<void> {
  const TenantAdminStaticProfileTypesListRoute({
    List<_i56.PageRouteInfo>? children,
  }) : super(
          TenantAdminStaticProfileTypesListRoute.name,
          initialChildren: children,
        );

  static const String name = 'TenantAdminStaticProfileTypesListRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      return const _i48.TenantAdminStaticProfileTypesListRoutePage();
    },
  );
}

/// generated route for
/// [_i49.TenantAdminTaxonomiesListRoutePage]
class TenantAdminTaxonomiesListRoute extends _i56.PageRouteInfo<void> {
  const TenantAdminTaxonomiesListRoute({List<_i56.PageRouteInfo>? children})
      : super(TenantAdminTaxonomiesListRoute.name, initialChildren: children);

  static const String name = 'TenantAdminTaxonomiesListRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      return const _i49.TenantAdminTaxonomiesListRoutePage();
    },
  );
}

/// generated route for
/// [_i50.TenantAdminTaxonomyCreateRoutePage]
class TenantAdminTaxonomyCreateRoute extends _i56.PageRouteInfo<void> {
  const TenantAdminTaxonomyCreateRoute({List<_i56.PageRouteInfo>? children})
      : super(TenantAdminTaxonomyCreateRoute.name, initialChildren: children);

  static const String name = 'TenantAdminTaxonomyCreateRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      return const _i50.TenantAdminTaxonomyCreateRoutePage();
    },
  );
}

/// generated route for
/// [_i50.TenantAdminTaxonomyEditRoutePage]
class TenantAdminTaxonomyEditRoute
    extends _i56.PageRouteInfo<TenantAdminTaxonomyEditRouteArgs> {
  TenantAdminTaxonomyEditRoute({
    _i57.Key? key,
    required String taxonomyId,
    required _i66.TenantAdminTaxonomyDefinition taxonomy,
    List<_i56.PageRouteInfo>? children,
  }) : super(
          TenantAdminTaxonomyEditRoute.name,
          args: TenantAdminTaxonomyEditRouteArgs(
            key: key,
            taxonomyId: taxonomyId,
            taxonomy: taxonomy,
          ),
          rawPathParams: {'taxonomyId': taxonomyId},
          initialChildren: children,
        );

  static const String name = 'TenantAdminTaxonomyEditRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TenantAdminTaxonomyEditRouteArgs>();
      return _i50.TenantAdminTaxonomyEditRoutePage(
        key: args.key,
        taxonomyId: args.taxonomyId,
        taxonomy: args.taxonomy,
      );
    },
  );
}

class TenantAdminTaxonomyEditRouteArgs {
  const TenantAdminTaxonomyEditRouteArgs({
    this.key,
    required this.taxonomyId,
    required this.taxonomy,
  });

  final _i57.Key? key;

  final String taxonomyId;

  final _i66.TenantAdminTaxonomyDefinition taxonomy;

  @override
  String toString() {
    return 'TenantAdminTaxonomyEditRouteArgs{key: $key, taxonomyId: $taxonomyId, taxonomy: $taxonomy}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TenantAdminTaxonomyEditRouteArgs) return false;
    return key == other.key &&
        taxonomyId == other.taxonomyId &&
        taxonomy == other.taxonomy;
  }

  @override
  int get hashCode => key.hashCode ^ taxonomyId.hashCode ^ taxonomy.hashCode;
}

/// generated route for
/// [_i51.TenantAdminTaxonomyTermCreateRoutePage]
class TenantAdminTaxonomyTermCreateRoute
    extends _i56.PageRouteInfo<TenantAdminTaxonomyTermCreateRouteArgs> {
  TenantAdminTaxonomyTermCreateRoute({
    _i57.Key? key,
    required String taxonomyId,
    required String taxonomyName,
    List<_i56.PageRouteInfo>? children,
  }) : super(
          TenantAdminTaxonomyTermCreateRoute.name,
          args: TenantAdminTaxonomyTermCreateRouteArgs(
            key: key,
            taxonomyId: taxonomyId,
            taxonomyName: taxonomyName,
          ),
          rawPathParams: {'taxonomyId': taxonomyId},
          initialChildren: children,
        );

  static const String name = 'TenantAdminTaxonomyTermCreateRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TenantAdminTaxonomyTermCreateRouteArgs>();
      return _i51.TenantAdminTaxonomyTermCreateRoutePage(
        key: args.key,
        taxonomyId: args.taxonomyId,
        taxonomyName: args.taxonomyName,
      );
    },
  );
}

class TenantAdminTaxonomyTermCreateRouteArgs {
  const TenantAdminTaxonomyTermCreateRouteArgs({
    this.key,
    required this.taxonomyId,
    required this.taxonomyName,
  });

  final _i57.Key? key;

  final String taxonomyId;

  final String taxonomyName;

  @override
  String toString() {
    return 'TenantAdminTaxonomyTermCreateRouteArgs{key: $key, taxonomyId: $taxonomyId, taxonomyName: $taxonomyName}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TenantAdminTaxonomyTermCreateRouteArgs) return false;
    return key == other.key &&
        taxonomyId == other.taxonomyId &&
        taxonomyName == other.taxonomyName;
  }

  @override
  int get hashCode =>
      key.hashCode ^ taxonomyId.hashCode ^ taxonomyName.hashCode;
}

/// generated route for
/// [_i52.TenantAdminTaxonomyTermDetailRoutePage]
class TenantAdminTaxonomyTermDetailRoute
    extends _i56.PageRouteInfo<TenantAdminTaxonomyTermDetailRouteArgs> {
  TenantAdminTaxonomyTermDetailRoute({
    _i57.Key? key,
    required String taxonomyId,
    required String taxonomyName,
    required String termId,
    required _i67.TenantAdminTaxonomyTermDefinition term,
    List<_i56.PageRouteInfo>? children,
  }) : super(
          TenantAdminTaxonomyTermDetailRoute.name,
          args: TenantAdminTaxonomyTermDetailRouteArgs(
            key: key,
            taxonomyId: taxonomyId,
            taxonomyName: taxonomyName,
            termId: termId,
            term: term,
          ),
          rawPathParams: {'taxonomyId': taxonomyId, 'termId': termId},
          initialChildren: children,
        );

  static const String name = 'TenantAdminTaxonomyTermDetailRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TenantAdminTaxonomyTermDetailRouteArgs>();
      return _i52.TenantAdminTaxonomyTermDetailRoutePage(
        key: args.key,
        taxonomyId: args.taxonomyId,
        taxonomyName: args.taxonomyName,
        termId: args.termId,
        term: args.term,
      );
    },
  );
}

class TenantAdminTaxonomyTermDetailRouteArgs {
  const TenantAdminTaxonomyTermDetailRouteArgs({
    this.key,
    required this.taxonomyId,
    required this.taxonomyName,
    required this.termId,
    required this.term,
  });

  final _i57.Key? key;

  final String taxonomyId;

  final String taxonomyName;

  final String termId;

  final _i67.TenantAdminTaxonomyTermDefinition term;

  @override
  String toString() {
    return 'TenantAdminTaxonomyTermDetailRouteArgs{key: $key, taxonomyId: $taxonomyId, taxonomyName: $taxonomyName, termId: $termId, term: $term}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TenantAdminTaxonomyTermDetailRouteArgs) return false;
    return key == other.key &&
        taxonomyId == other.taxonomyId &&
        taxonomyName == other.taxonomyName &&
        termId == other.termId &&
        term == other.term;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      taxonomyId.hashCode ^
      taxonomyName.hashCode ^
      termId.hashCode ^
      term.hashCode;
}

/// generated route for
/// [_i51.TenantAdminTaxonomyTermEditRoutePage]
class TenantAdminTaxonomyTermEditRoute
    extends _i56.PageRouteInfo<TenantAdminTaxonomyTermEditRouteArgs> {
  TenantAdminTaxonomyTermEditRoute({
    _i57.Key? key,
    required String taxonomyId,
    required String taxonomyName,
    required String termId,
    required _i67.TenantAdminTaxonomyTermDefinition term,
    List<_i56.PageRouteInfo>? children,
  }) : super(
          TenantAdminTaxonomyTermEditRoute.name,
          args: TenantAdminTaxonomyTermEditRouteArgs(
            key: key,
            taxonomyId: taxonomyId,
            taxonomyName: taxonomyName,
            termId: termId,
            term: term,
          ),
          rawPathParams: {'taxonomyId': taxonomyId, 'termId': termId},
          initialChildren: children,
        );

  static const String name = 'TenantAdminTaxonomyTermEditRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TenantAdminTaxonomyTermEditRouteArgs>();
      return _i51.TenantAdminTaxonomyTermEditRoutePage(
        key: args.key,
        taxonomyId: args.taxonomyId,
        taxonomyName: args.taxonomyName,
        termId: args.termId,
        term: args.term,
      );
    },
  );
}

class TenantAdminTaxonomyTermEditRouteArgs {
  const TenantAdminTaxonomyTermEditRouteArgs({
    this.key,
    required this.taxonomyId,
    required this.taxonomyName,
    required this.termId,
    required this.term,
  });

  final _i57.Key? key;

  final String taxonomyId;

  final String taxonomyName;

  final String termId;

  final _i67.TenantAdminTaxonomyTermDefinition term;

  @override
  String toString() {
    return 'TenantAdminTaxonomyTermEditRouteArgs{key: $key, taxonomyId: $taxonomyId, taxonomyName: $taxonomyName, termId: $termId, term: $term}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TenantAdminTaxonomyTermEditRouteArgs) return false;
    return key == other.key &&
        taxonomyId == other.taxonomyId &&
        taxonomyName == other.taxonomyName &&
        termId == other.termId &&
        term == other.term;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      taxonomyId.hashCode ^
      taxonomyName.hashCode ^
      termId.hashCode ^
      term.hashCode;
}

/// generated route for
/// [_i53.TenantAdminTaxonomyTermsRoutePage]
class TenantAdminTaxonomyTermsRoute
    extends _i56.PageRouteInfo<TenantAdminTaxonomyTermsRouteArgs> {
  TenantAdminTaxonomyTermsRoute({
    _i57.Key? key,
    required String taxonomyId,
    required String taxonomyName,
    List<_i56.PageRouteInfo>? children,
  }) : super(
          TenantAdminTaxonomyTermsRoute.name,
          args: TenantAdminTaxonomyTermsRouteArgs(
            key: key,
            taxonomyId: taxonomyId,
            taxonomyName: taxonomyName,
          ),
          rawPathParams: {'taxonomyId': taxonomyId},
          initialChildren: children,
        );

  static const String name = 'TenantAdminTaxonomyTermsRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TenantAdminTaxonomyTermsRouteArgs>();
      return _i53.TenantAdminTaxonomyTermsRoutePage(
        key: args.key,
        taxonomyId: args.taxonomyId,
        taxonomyName: args.taxonomyName,
      );
    },
  );
}

class TenantAdminTaxonomyTermsRouteArgs {
  const TenantAdminTaxonomyTermsRouteArgs({
    this.key,
    required this.taxonomyId,
    required this.taxonomyName,
  });

  final _i57.Key? key;

  final String taxonomyId;

  final String taxonomyName;

  @override
  String toString() {
    return 'TenantAdminTaxonomyTermsRouteArgs{key: $key, taxonomyId: $taxonomyId, taxonomyName: $taxonomyName}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TenantAdminTaxonomyTermsRouteArgs) return false;
    return key == other.key &&
        taxonomyId == other.taxonomyId &&
        taxonomyName == other.taxonomyName;
  }

  @override
  int get hashCode =>
      key.hashCode ^ taxonomyId.hashCode ^ taxonomyName.hashCode;
}

/// generated route for
/// [_i54.TenantHomeRoutePage]
class TenantHomeRoute extends _i56.PageRouteInfo<void> {
  const TenantHomeRoute({List<_i56.PageRouteInfo>? children})
      : super(TenantHomeRoute.name, initialChildren: children);

  static const String name = 'TenantHomeRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      return const _i54.TenantHomeRoutePage();
    },
  );
}

/// generated route for
/// [_i55.TenantMenuRoutePage]
class TenantMenuRoute extends _i56.PageRouteInfo<void> {
  const TenantMenuRoute({List<_i56.PageRouteInfo>? children})
      : super(TenantMenuRoute.name, initialChildren: children);

  static const String name = 'TenantMenuRoute';

  static _i56.PageInfo page = _i56.PageInfo(
    name,
    builder: (data) {
      return const _i55.TenantMenuRoutePage();
    },
  );
}
