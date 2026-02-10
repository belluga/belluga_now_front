// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i42;
import 'package:belluga_now/application/router/guards/location_permission_state.dart'
    as _i46;
import 'package:belluga_now/domain/invites/invite_model.dart' as _i45;
import 'package:belluga_now/domain/map/city_poi_model.dart' as _i47;
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart'
    as _i48;
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart'
    as _i49;
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart'
    as _i50;
import 'package:belluga_now/presentation/common/auth/routes/auth_create_new_password_route.dart'
    as _i1;
import 'package:belluga_now/presentation/common/auth/routes/auth_login_route.dart'
    as _i2;
import 'package:belluga_now/presentation/common/auth/routes/recovery_password_route.dart'
    as _i17;
import 'package:belluga_now/presentation/common/init/routes/init_route.dart'
    as _i8;
import 'package:belluga_now/presentation/common/location_permission/routes/location_not_live_route.dart'
    as _i12;
import 'package:belluga_now/presentation/common/location_permission/routes/location_permission_route.dart'
    as _i13;
import 'package:belluga_now/presentation/landlord/home/routes/landlord_home_route.dart'
    as _i11;
import 'package:belluga_now/presentation/tenant/discovery/routes/discovery_route.dart'
    as _i4;
import 'package:belluga_now/presentation/tenant/home/routes/tenant_home_route.dart'
    as _i40;
import 'package:belluga_now/presentation/tenant/invites/routes/invite_flow_route.dart'
    as _i9;
import 'package:belluga_now/presentation/tenant/invites/routes/invite_share_route.dart'
    as _i10;
import 'package:belluga_now/presentation/tenant/map/routes/city_map_route.dart'
    as _i3;
import 'package:belluga_now/presentation/tenant/map/routes/poi_details_route.dart'
    as _i15;
import 'package:belluga_now/presentation/tenant/menu/routes/tenant_menu_route.dart'
    as _i41;
import 'package:belluga_now/presentation/tenant/partners/routes/partner_detail_route.dart'
    as _i14;
import 'package:belluga_now/presentation/tenant/profile/routes/profile_route.dart'
    as _i16;
import 'package:belluga_now/presentation/tenant/schedule/routes/event_detail_route.dart'
    as _i5;
import 'package:belluga_now/presentation/tenant/schedule/routes/event_search_route.dart'
    as _i6;
import 'package:belluga_now/presentation/tenant/schedule/routes/immersive_event_detail_route.dart'
    as _i7;
import 'package:belluga_now/presentation/tenant/schedule/screens/event_search_screen/models/invite_filter.dart'
    as _i44;
import 'package:belluga_now/presentation/tenant_admin/account_profiles/routes/tenant_admin_account_profile_create_route.dart'
    as _i20;
import 'package:belluga_now/presentation/tenant_admin/account_profiles/routes/tenant_admin_account_profile_edit_route.dart'
    as _i21;
import 'package:belluga_now/presentation/tenant_admin/accounts/routes/tenant_admin_account_create_route.dart'
    as _i18;
import 'package:belluga_now/presentation/tenant_admin/accounts/routes/tenant_admin_account_detail_route.dart'
    as _i19;
import 'package:belluga_now/presentation/tenant_admin/accounts/routes/tenant_admin_accounts_list_route.dart'
    as _i22;
import 'package:belluga_now/presentation/tenant_admin/accounts/screens/tenant_admin_location_picker_screen.dart'
    as _i24;
import 'package:belluga_now/presentation/tenant_admin/organizations/routes/tenant_admin_organization_create_route.dart'
    as _i25;
import 'package:belluga_now/presentation/tenant_admin/organizations/routes/tenant_admin_organization_detail_route.dart'
    as _i26;
import 'package:belluga_now/presentation/tenant_admin/organizations/routes/tenant_admin_organizations_list_route.dart'
    as _i27;
import 'package:belluga_now/presentation/tenant_admin/profile_types/routes/tenant_admin_profile_type_create_route.dart'
    as _i28;
import 'package:belluga_now/presentation/tenant_admin/profile_types/routes/tenant_admin_profile_type_edit_route.dart'
    as _i29;
import 'package:belluga_now/presentation/tenant_admin/profile_types/routes/tenant_admin_profile_types_list_route.dart'
    as _i30;
import 'package:belluga_now/presentation/tenant_admin/shell/routes/tenant_admin_dashboard_route.dart'
    as _i23;
import 'package:belluga_now/presentation/tenant_admin/shell/routes/tenant_admin_shell_route.dart'
    as _i31;
import 'package:belluga_now/presentation/tenant_admin/static_assets/routes/tenant_admin_static_asset_create_route.dart'
    as _i32;
import 'package:belluga_now/presentation/tenant_admin/static_assets/routes/tenant_admin_static_asset_edit_route.dart'
    as _i33;
import 'package:belluga_now/presentation/tenant_admin/static_assets/routes/tenant_admin_static_assets_list_route.dart'
    as _i34;
import 'package:belluga_now/presentation/tenant_admin/static_profile_types/routes/tenant_admin_static_profile_type_create_route.dart'
    as _i35;
import 'package:belluga_now/presentation/tenant_admin/static_profile_types/routes/tenant_admin_static_profile_type_edit_route.dart'
    as _i36;
import 'package:belluga_now/presentation/tenant_admin/static_profile_types/routes/tenant_admin_static_profile_types_list_route.dart'
    as _i37;
import 'package:belluga_now/presentation/tenant_admin/taxonomies/routes/tenant_admin_taxonomies_list_route.dart'
    as _i38;
import 'package:belluga_now/presentation/tenant_admin/taxonomies/routes/tenant_admin_taxonomy_terms_route.dart'
    as _i39;
import 'package:flutter/material.dart' as _i43;

/// generated route for
/// [_i1.AuthCreateNewPasswordRoutePage]
class AuthCreateNewPasswordRoute extends _i42.PageRouteInfo<void> {
  const AuthCreateNewPasswordRoute({List<_i42.PageRouteInfo>? children})
      : super(AuthCreateNewPasswordRoute.name, initialChildren: children);

  static const String name = 'AuthCreateNewPasswordRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      return const _i1.AuthCreateNewPasswordRoutePage();
    },
  );
}

/// generated route for
/// [_i2.AuthLoginRoutePage]
class AuthLoginRoute extends _i42.PageRouteInfo<void> {
  const AuthLoginRoute({List<_i42.PageRouteInfo>? children})
      : super(AuthLoginRoute.name, initialChildren: children);

  static const String name = 'AuthLoginRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      return const _i2.AuthLoginRoutePage();
    },
  );
}

/// generated route for
/// [_i3.CityMapRoutePage]
class CityMapRoute extends _i42.PageRouteInfo<void> {
  const CityMapRoute({List<_i42.PageRouteInfo>? children})
      : super(CityMapRoute.name, initialChildren: children);

  static const String name = 'CityMapRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      return const _i3.CityMapRoutePage();
    },
  );
}

/// generated route for
/// [_i4.DiscoveryRoute]
class DiscoveryRoute extends _i42.PageRouteInfo<void> {
  const DiscoveryRoute({List<_i42.PageRouteInfo>? children})
      : super(DiscoveryRoute.name, initialChildren: children);

  static const String name = 'DiscoveryRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      return const _i4.DiscoveryRoute();
    },
  );
}

/// generated route for
/// [_i5.EventDetailRoutePage]
class EventDetailRoute extends _i42.PageRouteInfo<EventDetailRouteArgs> {
  EventDetailRoute({
    _i43.Key? key,
    required String slug,
    List<_i42.PageRouteInfo>? children,
  }) : super(
          EventDetailRoute.name,
          args: EventDetailRouteArgs(key: key, slug: slug),
          rawPathParams: {'slug': slug},
          initialChildren: children,
        );

  static const String name = 'EventDetailRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<EventDetailRouteArgs>(
        orElse: () => EventDetailRouteArgs(slug: pathParams.getString('slug')),
      );
      return _i5.EventDetailRoutePage(key: args.key, slug: args.slug);
    },
  );
}

class EventDetailRouteArgs {
  const EventDetailRouteArgs({this.key, required this.slug});

  final _i43.Key? key;

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
/// [_i6.EventSearchRoute]
class EventSearchRoute extends _i42.PageRouteInfo<EventSearchRouteArgs> {
  EventSearchRoute({
    _i43.Key? key,
    bool startSearchActive = false,
    String? initialSearchQuery,
    _i44.InviteFilter inviteFilter = _i44.InviteFilter.none,
    bool startWithHistory = false,
    List<_i42.PageRouteInfo>? children,
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

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<EventSearchRouteArgs>(
        orElse: () => const EventSearchRouteArgs(),
      );
      return _i6.EventSearchRoute(
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
    this.inviteFilter = _i44.InviteFilter.none,
    this.startWithHistory = false,
  });

  final _i43.Key? key;

  final bool startSearchActive;

  final String? initialSearchQuery;

  final _i44.InviteFilter inviteFilter;

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
/// [_i7.ImmersiveEventDetailRoutePage]
class ImmersiveEventDetailRoute
    extends _i42.PageRouteInfo<ImmersiveEventDetailRouteArgs> {
  ImmersiveEventDetailRoute({
    _i43.Key? key,
    required String eventSlug,
    List<_i42.PageRouteInfo>? children,
  }) : super(
          ImmersiveEventDetailRoute.name,
          args: ImmersiveEventDetailRouteArgs(key: key, eventSlug: eventSlug),
          rawPathParams: {'slug': eventSlug},
          initialChildren: children,
        );

  static const String name = 'ImmersiveEventDetailRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<ImmersiveEventDetailRouteArgs>(
        orElse: () => ImmersiveEventDetailRouteArgs(
          eventSlug: pathParams.getString('slug'),
        ),
      );
      return _i7.ImmersiveEventDetailRoutePage(
        key: args.key,
        eventSlug: args.eventSlug,
      );
    },
  );
}

class ImmersiveEventDetailRouteArgs {
  const ImmersiveEventDetailRouteArgs({this.key, required this.eventSlug});

  final _i43.Key? key;

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
/// [_i8.InitRoutePage]
class InitRoute extends _i42.PageRouteInfo<void> {
  const InitRoute({List<_i42.PageRouteInfo>? children})
      : super(InitRoute.name, initialChildren: children);

  static const String name = 'InitRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      return const _i8.InitRoutePage();
    },
  );
}

/// generated route for
/// [_i9.InviteFlowRoutePage]
class InviteFlowRoute extends _i42.PageRouteInfo<void> {
  const InviteFlowRoute({List<_i42.PageRouteInfo>? children})
      : super(InviteFlowRoute.name, initialChildren: children);

  static const String name = 'InviteFlowRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      return const _i9.InviteFlowRoutePage();
    },
  );
}

/// generated route for
/// [_i10.InviteShareRoutePage]
class InviteShareRoute extends _i42.PageRouteInfo<InviteShareRouteArgs> {
  InviteShareRoute({
    _i43.Key? key,
    required _i45.InviteModel invite,
    List<_i42.PageRouteInfo>? children,
  }) : super(
          InviteShareRoute.name,
          args: InviteShareRouteArgs(key: key, invite: invite),
          initialChildren: children,
        );

  static const String name = 'InviteShareRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<InviteShareRouteArgs>();
      return _i10.InviteShareRoutePage(key: args.key, invite: args.invite);
    },
  );
}

class InviteShareRouteArgs {
  const InviteShareRouteArgs({this.key, required this.invite});

  final _i43.Key? key;

  final _i45.InviteModel invite;

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
/// [_i11.LandlordHomeRoutePage]
class LandlordHomeRoute extends _i42.PageRouteInfo<void> {
  const LandlordHomeRoute({List<_i42.PageRouteInfo>? children})
      : super(LandlordHomeRoute.name, initialChildren: children);

  static const String name = 'LandlordHomeRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      return const _i11.LandlordHomeRoutePage();
    },
  );
}

/// generated route for
/// [_i12.LocationNotLiveRoutePage]
class LocationNotLiveRoute
    extends _i42.PageRouteInfo<LocationNotLiveRouteArgs> {
  LocationNotLiveRoute({
    _i43.Key? key,
    required _i46.LocationPermissionState blockerState,
    String? addressLabel,
    DateTime? capturedAt,
    List<_i42.PageRouteInfo>? children,
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

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<LocationNotLiveRouteArgs>();
      return _i12.LocationNotLiveRoutePage(
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

  final _i43.Key? key;

  final _i46.LocationPermissionState blockerState;

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
/// [_i13.LocationPermissionRoutePage]
class LocationPermissionRoute
    extends _i42.PageRouteInfo<LocationPermissionRouteArgs> {
  LocationPermissionRoute({
    _i43.Key? key,
    required _i46.LocationPermissionState initialState,
    List<_i42.PageRouteInfo>? children,
  }) : super(
          LocationPermissionRoute.name,
          args: LocationPermissionRouteArgs(
            key: key,
            initialState: initialState,
          ),
          initialChildren: children,
        );

  static const String name = 'LocationPermissionRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<LocationPermissionRouteArgs>();
      return _i13.LocationPermissionRoutePage(
        key: args.key,
        initialState: args.initialState,
      );
    },
  );
}

class LocationPermissionRouteArgs {
  const LocationPermissionRouteArgs({this.key, required this.initialState});

  final _i43.Key? key;

  final _i46.LocationPermissionState initialState;

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
/// [_i14.PartnerDetailRoute]
class PartnerDetailRoute extends _i42.PageRouteInfo<PartnerDetailRouteArgs> {
  PartnerDetailRoute({
    _i43.Key? key,
    required String slug,
    List<_i42.PageRouteInfo>? children,
  }) : super(
          PartnerDetailRoute.name,
          args: PartnerDetailRouteArgs(key: key, slug: slug),
          rawPathParams: {'slug': slug},
          initialChildren: children,
        );

  static const String name = 'PartnerDetailRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<PartnerDetailRouteArgs>(
        orElse: () =>
            PartnerDetailRouteArgs(slug: pathParams.getString('slug')),
      );
      return _i14.PartnerDetailRoute(key: args.key, slug: args.slug);
    },
  );
}

class PartnerDetailRouteArgs {
  const PartnerDetailRouteArgs({this.key, required this.slug});

  final _i43.Key? key;

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
/// [_i15.PoiDetailsRoutePage]
class PoiDetailsRoute extends _i42.PageRouteInfo<PoiDetailsRouteArgs> {
  PoiDetailsRoute({
    _i43.Key? key,
    required _i47.CityPoiModel poi,
    List<_i42.PageRouteInfo>? children,
  }) : super(
          PoiDetailsRoute.name,
          args: PoiDetailsRouteArgs(key: key, poi: poi),
          initialChildren: children,
        );

  static const String name = 'PoiDetailsRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PoiDetailsRouteArgs>();
      return _i15.PoiDetailsRoutePage(key: args.key, poi: args.poi);
    },
  );
}

class PoiDetailsRouteArgs {
  const PoiDetailsRouteArgs({this.key, required this.poi});

  final _i43.Key? key;

  final _i47.CityPoiModel poi;

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
/// [_i16.ProfileRoutePage]
class ProfileRoute extends _i42.PageRouteInfo<void> {
  const ProfileRoute({List<_i42.PageRouteInfo>? children})
      : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      return const _i16.ProfileRoutePage();
    },
  );
}

/// generated route for
/// [_i17.RecoveryPasswordRoutePage]
class RecoveryPasswordRoute
    extends _i42.PageRouteInfo<RecoveryPasswordRouteArgs> {
  RecoveryPasswordRoute({
    _i43.Key? key,
    String? initialEmmail,
    List<_i42.PageRouteInfo>? children,
  }) : super(
          RecoveryPasswordRoute.name,
          args: RecoveryPasswordRouteArgs(
            key: key,
            initialEmmail: initialEmmail,
          ),
          initialChildren: children,
        );

  static const String name = 'RecoveryPasswordRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RecoveryPasswordRouteArgs>(
        orElse: () => const RecoveryPasswordRouteArgs(),
      );
      return _i17.RecoveryPasswordRoutePage(
        key: args.key,
        initialEmmail: args.initialEmmail,
      );
    },
  );
}

class RecoveryPasswordRouteArgs {
  const RecoveryPasswordRouteArgs({this.key, this.initialEmmail});

  final _i43.Key? key;

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
/// [_i18.TenantAdminAccountCreateRoutePage]
class TenantAdminAccountCreateRoute extends _i42.PageRouteInfo<void> {
  const TenantAdminAccountCreateRoute({List<_i42.PageRouteInfo>? children})
      : super(TenantAdminAccountCreateRoute.name, initialChildren: children);

  static const String name = 'TenantAdminAccountCreateRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      return const _i18.TenantAdminAccountCreateRoutePage();
    },
  );
}

/// generated route for
/// [_i19.TenantAdminAccountDetailRoutePage]
class TenantAdminAccountDetailRoute
    extends _i42.PageRouteInfo<TenantAdminAccountDetailRouteArgs> {
  TenantAdminAccountDetailRoute({
    _i43.Key? key,
    required String accountSlug,
    List<_i42.PageRouteInfo>? children,
  }) : super(
          TenantAdminAccountDetailRoute.name,
          args: TenantAdminAccountDetailRouteArgs(
            key: key,
            accountSlug: accountSlug,
          ),
          initialChildren: children,
        );

  static const String name = 'TenantAdminAccountDetailRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TenantAdminAccountDetailRouteArgs>();
      return _i19.TenantAdminAccountDetailRoutePage(
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

  final _i43.Key? key;

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
/// [_i20.TenantAdminAccountProfileCreateRoutePage]
class TenantAdminAccountProfileCreateRoute
    extends _i42.PageRouteInfo<TenantAdminAccountProfileCreateRouteArgs> {
  TenantAdminAccountProfileCreateRoute({
    _i43.Key? key,
    required String accountSlug,
    List<_i42.PageRouteInfo>? children,
  }) : super(
          TenantAdminAccountProfileCreateRoute.name,
          args: TenantAdminAccountProfileCreateRouteArgs(
            key: key,
            accountSlug: accountSlug,
          ),
          initialChildren: children,
        );

  static const String name = 'TenantAdminAccountProfileCreateRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TenantAdminAccountProfileCreateRouteArgs>();
      return _i20.TenantAdminAccountProfileCreateRoutePage(
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

  final _i43.Key? key;

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
/// [_i21.TenantAdminAccountProfileEditRoutePage]
class TenantAdminAccountProfileEditRoute
    extends _i42.PageRouteInfo<TenantAdminAccountProfileEditRouteArgs> {
  TenantAdminAccountProfileEditRoute({
    _i43.Key? key,
    required String accountProfileId,
    List<_i42.PageRouteInfo>? children,
  }) : super(
          TenantAdminAccountProfileEditRoute.name,
          args: TenantAdminAccountProfileEditRouteArgs(
            key: key,
            accountProfileId: accountProfileId,
          ),
          initialChildren: children,
        );

  static const String name = 'TenantAdminAccountProfileEditRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TenantAdminAccountProfileEditRouteArgs>();
      return _i21.TenantAdminAccountProfileEditRoutePage(
        key: args.key,
        accountProfileId: args.accountProfileId,
      );
    },
  );
}

class TenantAdminAccountProfileEditRouteArgs {
  const TenantAdminAccountProfileEditRouteArgs({
    this.key,
    required this.accountProfileId,
  });

  final _i43.Key? key;

  final String accountProfileId;

  @override
  String toString() {
    return 'TenantAdminAccountProfileEditRouteArgs{key: $key, accountProfileId: $accountProfileId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TenantAdminAccountProfileEditRouteArgs) return false;
    return key == other.key && accountProfileId == other.accountProfileId;
  }

  @override
  int get hashCode => key.hashCode ^ accountProfileId.hashCode;
}

/// generated route for
/// [_i22.TenantAdminAccountsListRoutePage]
class TenantAdminAccountsListRoute extends _i42.PageRouteInfo<void> {
  const TenantAdminAccountsListRoute({List<_i42.PageRouteInfo>? children})
      : super(TenantAdminAccountsListRoute.name, initialChildren: children);

  static const String name = 'TenantAdminAccountsListRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      return const _i22.TenantAdminAccountsListRoutePage();
    },
  );
}

/// generated route for
/// [_i23.TenantAdminDashboardRoutePage]
class TenantAdminDashboardRoute extends _i42.PageRouteInfo<void> {
  const TenantAdminDashboardRoute({List<_i42.PageRouteInfo>? children})
      : super(TenantAdminDashboardRoute.name, initialChildren: children);

  static const String name = 'TenantAdminDashboardRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      return const _i23.TenantAdminDashboardRoutePage();
    },
  );
}

/// generated route for
/// [_i24.TenantAdminLocationPickerScreen]
class TenantAdminLocationPickerRoute
    extends _i42.PageRouteInfo<TenantAdminLocationPickerRouteArgs> {
  TenantAdminLocationPickerRoute({
    _i43.Key? key,
    _i48.TenantAdminLocation? initialLocation,
    List<_i42.PageRouteInfo>? children,
  }) : super(
          TenantAdminLocationPickerRoute.name,
          args: TenantAdminLocationPickerRouteArgs(
            key: key,
            initialLocation: initialLocation,
          ),
          initialChildren: children,
        );

  static const String name = 'TenantAdminLocationPickerRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TenantAdminLocationPickerRouteArgs>(
        orElse: () => const TenantAdminLocationPickerRouteArgs(),
      );
      return _i24.TenantAdminLocationPickerScreen(
        key: args.key,
        initialLocation: args.initialLocation,
      );
    },
  );
}

class TenantAdminLocationPickerRouteArgs {
  const TenantAdminLocationPickerRouteArgs({this.key, this.initialLocation});

  final _i43.Key? key;

  final _i48.TenantAdminLocation? initialLocation;

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
/// [_i25.TenantAdminOrganizationCreateRoutePage]
class TenantAdminOrganizationCreateRoute extends _i42.PageRouteInfo<void> {
  const TenantAdminOrganizationCreateRoute({List<_i42.PageRouteInfo>? children})
      : super(TenantAdminOrganizationCreateRoute.name,
            initialChildren: children);

  static const String name = 'TenantAdminOrganizationCreateRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      return const _i25.TenantAdminOrganizationCreateRoutePage();
    },
  );
}

/// generated route for
/// [_i26.TenantAdminOrganizationDetailRoutePage]
class TenantAdminOrganizationDetailRoute
    extends _i42.PageRouteInfo<TenantAdminOrganizationDetailRouteArgs> {
  TenantAdminOrganizationDetailRoute({
    _i43.Key? key,
    required String organizationId,
    List<_i42.PageRouteInfo>? children,
  }) : super(
          TenantAdminOrganizationDetailRoute.name,
          args: TenantAdminOrganizationDetailRouteArgs(
            key: key,
            organizationId: organizationId,
          ),
          initialChildren: children,
        );

  static const String name = 'TenantAdminOrganizationDetailRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TenantAdminOrganizationDetailRouteArgs>();
      return _i26.TenantAdminOrganizationDetailRoutePage(
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

  final _i43.Key? key;

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
/// [_i27.TenantAdminOrganizationsListRoutePage]
class TenantAdminOrganizationsListRoute extends _i42.PageRouteInfo<void> {
  const TenantAdminOrganizationsListRoute({List<_i42.PageRouteInfo>? children})
      : super(TenantAdminOrganizationsListRoute.name,
            initialChildren: children);

  static const String name = 'TenantAdminOrganizationsListRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      return const _i27.TenantAdminOrganizationsListRoutePage();
    },
  );
}

/// generated route for
/// [_i28.TenantAdminProfileTypeCreateRoutePage]
class TenantAdminProfileTypeCreateRoute extends _i42.PageRouteInfo<void> {
  const TenantAdminProfileTypeCreateRoute({List<_i42.PageRouteInfo>? children})
      : super(TenantAdminProfileTypeCreateRoute.name,
            initialChildren: children);

  static const String name = 'TenantAdminProfileTypeCreateRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      return const _i28.TenantAdminProfileTypeCreateRoutePage();
    },
  );
}

/// generated route for
/// [_i29.TenantAdminProfileTypeEditRoutePage]
class TenantAdminProfileTypeEditRoute
    extends _i42.PageRouteInfo<TenantAdminProfileTypeEditRouteArgs> {
  TenantAdminProfileTypeEditRoute({
    _i43.Key? key,
    required String profileType,
    required _i49.TenantAdminProfileTypeDefinition definition,
    List<_i42.PageRouteInfo>? children,
  }) : super(
          TenantAdminProfileTypeEditRoute.name,
          args: TenantAdminProfileTypeEditRouteArgs(
            key: key,
            profileType: profileType,
            definition: definition,
          ),
          initialChildren: children,
        );

  static const String name = 'TenantAdminProfileTypeEditRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TenantAdminProfileTypeEditRouteArgs>();
      return _i29.TenantAdminProfileTypeEditRoutePage(
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

  final _i43.Key? key;

  final String profileType;

  final _i49.TenantAdminProfileTypeDefinition definition;

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
/// [_i30.TenantAdminProfileTypesListRoutePage]
class TenantAdminProfileTypesListRoute extends _i42.PageRouteInfo<void> {
  const TenantAdminProfileTypesListRoute({List<_i42.PageRouteInfo>? children})
      : super(TenantAdminProfileTypesListRoute.name, initialChildren: children);

  static const String name = 'TenantAdminProfileTypesListRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      return const _i30.TenantAdminProfileTypesListRoutePage();
    },
  );
}

/// generated route for
/// [_i31.TenantAdminShellRoutePage]
class TenantAdminShellRoute extends _i42.PageRouteInfo<void> {
  const TenantAdminShellRoute({List<_i42.PageRouteInfo>? children})
      : super(TenantAdminShellRoute.name, initialChildren: children);

  static const String name = 'TenantAdminShellRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      return const _i31.TenantAdminShellRoutePage();
    },
  );
}

/// generated route for
/// [_i32.TenantAdminStaticAssetCreateRoutePage]
class TenantAdminStaticAssetCreateRoute extends _i42.PageRouteInfo<void> {
  const TenantAdminStaticAssetCreateRoute({List<_i42.PageRouteInfo>? children})
      : super(TenantAdminStaticAssetCreateRoute.name,
            initialChildren: children);

  static const String name = 'TenantAdminStaticAssetCreateRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      return const _i32.TenantAdminStaticAssetCreateRoutePage();
    },
  );
}

/// generated route for
/// [_i33.TenantAdminStaticAssetEditRoutePage]
class TenantAdminStaticAssetEditRoute
    extends _i42.PageRouteInfo<TenantAdminStaticAssetEditRouteArgs> {
  TenantAdminStaticAssetEditRoute({
    _i43.Key? key,
    required String assetId,
    List<_i42.PageRouteInfo>? children,
  }) : super(
          TenantAdminStaticAssetEditRoute.name,
          args: TenantAdminStaticAssetEditRouteArgs(key: key, assetId: assetId),
          initialChildren: children,
        );

  static const String name = 'TenantAdminStaticAssetEditRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TenantAdminStaticAssetEditRouteArgs>();
      return _i33.TenantAdminStaticAssetEditRoutePage(
        key: args.key,
        assetId: args.assetId,
      );
    },
  );
}

class TenantAdminStaticAssetEditRouteArgs {
  const TenantAdminStaticAssetEditRouteArgs({this.key, required this.assetId});

  final _i43.Key? key;

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
/// [_i34.TenantAdminStaticAssetsListRoutePage]
class TenantAdminStaticAssetsListRoute extends _i42.PageRouteInfo<void> {
  const TenantAdminStaticAssetsListRoute({List<_i42.PageRouteInfo>? children})
      : super(TenantAdminStaticAssetsListRoute.name, initialChildren: children);

  static const String name = 'TenantAdminStaticAssetsListRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      return const _i34.TenantAdminStaticAssetsListRoutePage();
    },
  );
}

/// generated route for
/// [_i35.TenantAdminStaticProfileTypeCreateRoutePage]
class TenantAdminStaticProfileTypeCreateRoute extends _i42.PageRouteInfo<void> {
  const TenantAdminStaticProfileTypeCreateRoute({
    List<_i42.PageRouteInfo>? children,
  }) : super(
          TenantAdminStaticProfileTypeCreateRoute.name,
          initialChildren: children,
        );

  static const String name = 'TenantAdminStaticProfileTypeCreateRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      return const _i35.TenantAdminStaticProfileTypeCreateRoutePage();
    },
  );
}

/// generated route for
/// [_i36.TenantAdminStaticProfileTypeEditRoutePage]
class TenantAdminStaticProfileTypeEditRoute
    extends _i42.PageRouteInfo<TenantAdminStaticProfileTypeEditRouteArgs> {
  TenantAdminStaticProfileTypeEditRoute({
    _i43.Key? key,
    required String profileType,
    required _i50.TenantAdminStaticProfileTypeDefinition definition,
    List<_i42.PageRouteInfo>? children,
  }) : super(
          TenantAdminStaticProfileTypeEditRoute.name,
          args: TenantAdminStaticProfileTypeEditRouteArgs(
            key: key,
            profileType: profileType,
            definition: definition,
          ),
          initialChildren: children,
        );

  static const String name = 'TenantAdminStaticProfileTypeEditRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TenantAdminStaticProfileTypeEditRouteArgs>();
      return _i36.TenantAdminStaticProfileTypeEditRoutePage(
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

  final _i43.Key? key;

  final String profileType;

  final _i50.TenantAdminStaticProfileTypeDefinition definition;

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
/// [_i37.TenantAdminStaticProfileTypesListRoutePage]
class TenantAdminStaticProfileTypesListRoute extends _i42.PageRouteInfo<void> {
  const TenantAdminStaticProfileTypesListRoute({
    List<_i42.PageRouteInfo>? children,
  }) : super(
          TenantAdminStaticProfileTypesListRoute.name,
          initialChildren: children,
        );

  static const String name = 'TenantAdminStaticProfileTypesListRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      return const _i37.TenantAdminStaticProfileTypesListRoutePage();
    },
  );
}

/// generated route for
/// [_i38.TenantAdminTaxonomiesListRoutePage]
class TenantAdminTaxonomiesListRoute extends _i42.PageRouteInfo<void> {
  const TenantAdminTaxonomiesListRoute({List<_i42.PageRouteInfo>? children})
      : super(TenantAdminTaxonomiesListRoute.name, initialChildren: children);

  static const String name = 'TenantAdminTaxonomiesListRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      return const _i38.TenantAdminTaxonomiesListRoutePage();
    },
  );
}

/// generated route for
/// [_i39.TenantAdminTaxonomyTermsRoutePage]
class TenantAdminTaxonomyTermsRoute
    extends _i42.PageRouteInfo<TenantAdminTaxonomyTermsRouteArgs> {
  TenantAdminTaxonomyTermsRoute({
    _i43.Key? key,
    required String taxonomyId,
    required String taxonomyName,
    List<_i42.PageRouteInfo>? children,
  }) : super(
          TenantAdminTaxonomyTermsRoute.name,
          args: TenantAdminTaxonomyTermsRouteArgs(
            key: key,
            taxonomyId: taxonomyId,
            taxonomyName: taxonomyName,
          ),
          initialChildren: children,
        );

  static const String name = 'TenantAdminTaxonomyTermsRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TenantAdminTaxonomyTermsRouteArgs>();
      return _i39.TenantAdminTaxonomyTermsRoutePage(
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

  final _i43.Key? key;

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
/// [_i40.TenantHomeRoutePage]
class TenantHomeRoute extends _i42.PageRouteInfo<void> {
  const TenantHomeRoute({List<_i42.PageRouteInfo>? children})
      : super(TenantHomeRoute.name, initialChildren: children);

  static const String name = 'TenantHomeRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      return const _i40.TenantHomeRoutePage();
    },
  );
}

/// generated route for
/// [_i41.TenantMenuRoutePage]
class TenantMenuRoute extends _i42.PageRouteInfo<void> {
  const TenantMenuRoute({List<_i42.PageRouteInfo>? children})
      : super(TenantMenuRoute.name, initialChildren: children);

  static const String name = 'TenantMenuRoute';

  static _i42.PageInfo page = _i42.PageInfo(
    name,
    builder: (data) {
      return const _i41.TenantMenuRoutePage();
    },
  );
}
