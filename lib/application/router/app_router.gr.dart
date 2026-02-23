// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i54;
import 'package:belluga_now/application/router/guards/location_permission_state.dart'
    as _i58;
import 'package:belluga_now/domain/invites/invite_model.dart' as _i57;
import 'package:belluga_now/domain/map/city_poi_model.dart' as _i59;
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart'
    as _i60;
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart'
    as _i61;
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart'
    as _i63;
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart'
    as _i64;
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart'
    as _i65;
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
    as _i52;
import 'package:belluga_now/presentation/tenant/invites/routes/invite_flow_route.dart'
    as _i9;
import 'package:belluga_now/presentation/tenant/invites/routes/invite_share_route.dart'
    as _i10;
import 'package:belluga_now/presentation/tenant/map/routes/city_map_route.dart'
    as _i3;
import 'package:belluga_now/presentation/tenant/map/routes/poi_details_route.dart'
    as _i15;
import 'package:belluga_now/presentation/tenant/menu/routes/tenant_menu_route.dart'
    as _i53;
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
    as _i56;
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
    as _i25;
import 'package:belluga_now/presentation/tenant_admin/events/routes/tenant_admin_events_route.dart'
    as _i24;
import 'package:belluga_now/presentation/tenant_admin/organizations/routes/tenant_admin_organization_create_route.dart'
    as _i26;
import 'package:belluga_now/presentation/tenant_admin/organizations/routes/tenant_admin_organization_detail_route.dart'
    as _i27;
import 'package:belluga_now/presentation/tenant_admin/organizations/routes/tenant_admin_organizations_list_route.dart'
    as _i28;
import 'package:belluga_now/presentation/tenant_admin/profile_types/routes/tenant_admin_profile_type_create_route.dart'
    as _i29;
import 'package:belluga_now/presentation/tenant_admin/profile_types/routes/tenant_admin_profile_type_detail_route.dart'
    as _i30;
import 'package:belluga_now/presentation/tenant_admin/profile_types/routes/tenant_admin_profile_type_edit_route.dart'
    as _i31;
import 'package:belluga_now/presentation/tenant_admin/profile_types/routes/tenant_admin_profile_types_list_route.dart'
    as _i32;
import 'package:belluga_now/presentation/tenant_admin/settings/models/tenant_admin_settings_integration_section.dart'
    as _i62;
import 'package:belluga_now/presentation/tenant_admin/settings/routes/tenant_admin_settings_environment_snapshot_route.dart'
    as _i33;
import 'package:belluga_now/presentation/tenant_admin/settings/routes/tenant_admin_settings_local_preferences_route.dart'
    as _i34;
import 'package:belluga_now/presentation/tenant_admin/settings/routes/tenant_admin_settings_route.dart'
    as _i35;
import 'package:belluga_now/presentation/tenant_admin/settings/routes/tenant_admin_settings_technical_integrations_route.dart'
    as _i36;
import 'package:belluga_now/presentation/tenant_admin/settings/routes/tenant_admin_settings_visual_identity_route.dart'
    as _i37;
import 'package:belluga_now/presentation/tenant_admin/shell/routes/tenant_admin_dashboard_route.dart'
    as _i23;
import 'package:belluga_now/presentation/tenant_admin/shell/routes/tenant_admin_shell_route.dart'
    as _i38;
import 'package:belluga_now/presentation/tenant_admin/static_assets/routes/tenant_admin_static_asset_create_route.dart'
    as _i39;
import 'package:belluga_now/presentation/tenant_admin/static_assets/routes/tenant_admin_static_asset_detail_route.dart'
    as _i40;
import 'package:belluga_now/presentation/tenant_admin/static_assets/routes/tenant_admin_static_asset_edit_route.dart'
    as _i41;
import 'package:belluga_now/presentation/tenant_admin/static_assets/routes/tenant_admin_static_assets_list_route.dart'
    as _i42;
import 'package:belluga_now/presentation/tenant_admin/static_profile_types/routes/tenant_admin_static_profile_type_create_route.dart'
    as _i43;
import 'package:belluga_now/presentation/tenant_admin/static_profile_types/routes/tenant_admin_static_profile_type_detail_route.dart'
    as _i44;
import 'package:belluga_now/presentation/tenant_admin/static_profile_types/routes/tenant_admin_static_profile_type_edit_route.dart'
    as _i45;
import 'package:belluga_now/presentation/tenant_admin/static_profile_types/routes/tenant_admin_static_profile_types_list_route.dart'
    as _i46;
import 'package:belluga_now/presentation/tenant_admin/taxonomies/routes/tenant_admin_taxonomies_list_route.dart'
    as _i47;
import 'package:belluga_now/presentation/tenant_admin/taxonomies/routes/tenant_admin_taxonomy_form_route.dart'
    as _i48;
import 'package:belluga_now/presentation/tenant_admin/taxonomies/routes/tenant_admin_taxonomy_term_detail_route.dart'
    as _i50;
import 'package:belluga_now/presentation/tenant_admin/taxonomies/routes/tenant_admin_taxonomy_term_form_route.dart'
    as _i49;
import 'package:belluga_now/presentation/tenant_admin/taxonomies/routes/tenant_admin_taxonomy_terms_route.dart'
    as _i51;
import 'package:flutter/material.dart' as _i55;

/// generated route for
/// [_i1.AuthCreateNewPasswordRoutePage]
class AuthCreateNewPasswordRoute extends _i54.PageRouteInfo<void> {
  const AuthCreateNewPasswordRoute({List<_i54.PageRouteInfo>? children})
      : super(AuthCreateNewPasswordRoute.name, initialChildren: children);

  static const String name = 'AuthCreateNewPasswordRoute';

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      return const _i1.AuthCreateNewPasswordRoutePage();
    },
  );
}

/// generated route for
/// [_i2.AuthLoginRoutePage]
class AuthLoginRoute extends _i54.PageRouteInfo<void> {
  const AuthLoginRoute({List<_i54.PageRouteInfo>? children})
      : super(AuthLoginRoute.name, initialChildren: children);

  static const String name = 'AuthLoginRoute';

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      return const _i2.AuthLoginRoutePage();
    },
  );
}

/// generated route for
/// [_i3.CityMapRoutePage]
class CityMapRoute extends _i54.PageRouteInfo<void> {
  const CityMapRoute({List<_i54.PageRouteInfo>? children})
      : super(CityMapRoute.name, initialChildren: children);

  static const String name = 'CityMapRoute';

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      return const _i3.CityMapRoutePage();
    },
  );
}

/// generated route for
/// [_i4.DiscoveryRoute]
class DiscoveryRoute extends _i54.PageRouteInfo<void> {
  const DiscoveryRoute({List<_i54.PageRouteInfo>? children})
      : super(DiscoveryRoute.name, initialChildren: children);

  static const String name = 'DiscoveryRoute';

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      return const _i4.DiscoveryRoute();
    },
  );
}

/// generated route for
/// [_i5.EventDetailRoutePage]
class EventDetailRoute extends _i54.PageRouteInfo<EventDetailRouteArgs> {
  EventDetailRoute({
    _i55.Key? key,
    required String slug,
    List<_i54.PageRouteInfo>? children,
  }) : super(
          EventDetailRoute.name,
          args: EventDetailRouteArgs(key: key, slug: slug),
          rawPathParams: {'slug': slug},
          initialChildren: children,
        );

  static const String name = 'EventDetailRoute';

  static _i54.PageInfo page = _i54.PageInfo(
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

  final _i55.Key? key;

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
class EventSearchRoute extends _i54.PageRouteInfo<EventSearchRouteArgs> {
  EventSearchRoute({
    _i55.Key? key,
    bool startSearchActive = false,
    String? initialSearchQuery,
    _i56.InviteFilter inviteFilter = _i56.InviteFilter.none,
    bool startWithHistory = false,
    List<_i54.PageRouteInfo>? children,
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

  static _i54.PageInfo page = _i54.PageInfo(
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
    this.inviteFilter = _i56.InviteFilter.none,
    this.startWithHistory = false,
  });

  final _i55.Key? key;

  final bool startSearchActive;

  final String? initialSearchQuery;

  final _i56.InviteFilter inviteFilter;

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
    extends _i54.PageRouteInfo<ImmersiveEventDetailRouteArgs> {
  ImmersiveEventDetailRoute({
    _i55.Key? key,
    required String eventSlug,
    List<_i54.PageRouteInfo>? children,
  }) : super(
          ImmersiveEventDetailRoute.name,
          args: ImmersiveEventDetailRouteArgs(key: key, eventSlug: eventSlug),
          rawPathParams: {'slug': eventSlug},
          initialChildren: children,
        );

  static const String name = 'ImmersiveEventDetailRoute';

  static _i54.PageInfo page = _i54.PageInfo(
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

  final _i55.Key? key;

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
class InitRoute extends _i54.PageRouteInfo<void> {
  const InitRoute({List<_i54.PageRouteInfo>? children})
      : super(InitRoute.name, initialChildren: children);

  static const String name = 'InitRoute';

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      return const _i8.InitRoutePage();
    },
  );
}

/// generated route for
/// [_i9.InviteFlowRoutePage]
class InviteFlowRoute extends _i54.PageRouteInfo<void> {
  const InviteFlowRoute({List<_i54.PageRouteInfo>? children})
      : super(InviteFlowRoute.name, initialChildren: children);

  static const String name = 'InviteFlowRoute';

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      return const _i9.InviteFlowRoutePage();
    },
  );
}

/// generated route for
/// [_i10.InviteShareRoutePage]
class InviteShareRoute extends _i54.PageRouteInfo<InviteShareRouteArgs> {
  InviteShareRoute({
    _i55.Key? key,
    required _i57.InviteModel invite,
    List<_i54.PageRouteInfo>? children,
  }) : super(
          InviteShareRoute.name,
          args: InviteShareRouteArgs(key: key, invite: invite),
          initialChildren: children,
        );

  static const String name = 'InviteShareRoute';

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<InviteShareRouteArgs>();
      return _i10.InviteShareRoutePage(key: args.key, invite: args.invite);
    },
  );
}

class InviteShareRouteArgs {
  const InviteShareRouteArgs({this.key, required this.invite});

  final _i55.Key? key;

  final _i57.InviteModel invite;

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
class LandlordHomeRoute extends _i54.PageRouteInfo<void> {
  const LandlordHomeRoute({List<_i54.PageRouteInfo>? children})
      : super(LandlordHomeRoute.name, initialChildren: children);

  static const String name = 'LandlordHomeRoute';

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      return const _i11.LandlordHomeRoutePage();
    },
  );
}

/// generated route for
/// [_i12.LocationNotLiveRoutePage]
class LocationNotLiveRoute
    extends _i54.PageRouteInfo<LocationNotLiveRouteArgs> {
  LocationNotLiveRoute({
    _i55.Key? key,
    required _i58.LocationPermissionState blockerState,
    String? addressLabel,
    DateTime? capturedAt,
    List<_i54.PageRouteInfo>? children,
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

  static _i54.PageInfo page = _i54.PageInfo(
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

  final _i55.Key? key;

  final _i58.LocationPermissionState blockerState;

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
    extends _i54.PageRouteInfo<LocationPermissionRouteArgs> {
  LocationPermissionRoute({
    _i55.Key? key,
    required _i58.LocationPermissionState initialState,
    List<_i54.PageRouteInfo>? children,
  }) : super(
          LocationPermissionRoute.name,
          args: LocationPermissionRouteArgs(
            key: key,
            initialState: initialState,
          ),
          initialChildren: children,
        );

  static const String name = 'LocationPermissionRoute';

  static _i54.PageInfo page = _i54.PageInfo(
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

  final _i55.Key? key;

  final _i58.LocationPermissionState initialState;

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
class PartnerDetailRoute extends _i54.PageRouteInfo<PartnerDetailRouteArgs> {
  PartnerDetailRoute({
    _i55.Key? key,
    required String slug,
    List<_i54.PageRouteInfo>? children,
  }) : super(
          PartnerDetailRoute.name,
          args: PartnerDetailRouteArgs(key: key, slug: slug),
          rawPathParams: {'slug': slug},
          initialChildren: children,
        );

  static const String name = 'PartnerDetailRoute';

  static _i54.PageInfo page = _i54.PageInfo(
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

  final _i55.Key? key;

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
class PoiDetailsRoute extends _i54.PageRouteInfo<PoiDetailsRouteArgs> {
  PoiDetailsRoute({
    _i55.Key? key,
    required _i59.CityPoiModel poi,
    List<_i54.PageRouteInfo>? children,
  }) : super(
          PoiDetailsRoute.name,
          args: PoiDetailsRouteArgs(key: key, poi: poi),
          initialChildren: children,
        );

  static const String name = 'PoiDetailsRoute';

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PoiDetailsRouteArgs>();
      return _i15.PoiDetailsRoutePage(key: args.key, poi: args.poi);
    },
  );
}

class PoiDetailsRouteArgs {
  const PoiDetailsRouteArgs({this.key, required this.poi});

  final _i55.Key? key;

  final _i59.CityPoiModel poi;

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
class ProfileRoute extends _i54.PageRouteInfo<void> {
  const ProfileRoute({List<_i54.PageRouteInfo>? children})
      : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      return const _i16.ProfileRoutePage();
    },
  );
}

/// generated route for
/// [_i17.RecoveryPasswordRoutePage]
class RecoveryPasswordRoute
    extends _i54.PageRouteInfo<RecoveryPasswordRouteArgs> {
  RecoveryPasswordRoute({
    _i55.Key? key,
    String? initialEmmail,
    List<_i54.PageRouteInfo>? children,
  }) : super(
          RecoveryPasswordRoute.name,
          args: RecoveryPasswordRouteArgs(
            key: key,
            initialEmmail: initialEmmail,
          ),
          initialChildren: children,
        );

  static const String name = 'RecoveryPasswordRoute';

  static _i54.PageInfo page = _i54.PageInfo(
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

  final _i55.Key? key;

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
class TenantAdminAccountCreateRoute extends _i54.PageRouteInfo<void> {
  const TenantAdminAccountCreateRoute({List<_i54.PageRouteInfo>? children})
      : super(TenantAdminAccountCreateRoute.name, initialChildren: children);

  static const String name = 'TenantAdminAccountCreateRoute';

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      return const _i18.TenantAdminAccountCreateRoutePage();
    },
  );
}

/// generated route for
/// [_i19.TenantAdminAccountDetailRoutePage]
class TenantAdminAccountDetailRoute
    extends _i54.PageRouteInfo<TenantAdminAccountDetailRouteArgs> {
  TenantAdminAccountDetailRoute({
    _i55.Key? key,
    required String accountSlug,
    List<_i54.PageRouteInfo>? children,
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

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminAccountDetailRouteArgs>(
        orElse: () => TenantAdminAccountDetailRouteArgs(
          accountSlug: pathParams.getString('accountSlug'),
        ),
      );
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

  final _i55.Key? key;

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
    extends _i54.PageRouteInfo<TenantAdminAccountProfileCreateRouteArgs> {
  TenantAdminAccountProfileCreateRoute({
    _i55.Key? key,
    required String accountSlug,
    List<_i54.PageRouteInfo>? children,
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

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminAccountProfileCreateRouteArgs>(
        orElse: () => TenantAdminAccountProfileCreateRouteArgs(
          accountSlug: pathParams.getString('accountSlug'),
        ),
      );
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

  final _i55.Key? key;

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
    extends _i54.PageRouteInfo<TenantAdminAccountProfileEditRouteArgs> {
  TenantAdminAccountProfileEditRoute({
    _i55.Key? key,
    required String accountSlug,
    required String accountProfileId,
    List<_i54.PageRouteInfo>? children,
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

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminAccountProfileEditRouteArgs>(
        orElse: () => TenantAdminAccountProfileEditRouteArgs(
          accountSlug: pathParams.getString('accountSlug'),
          accountProfileId: pathParams.getString('accountProfileId'),
        ),
      );
      return _i21.TenantAdminAccountProfileEditRoutePage(
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

  final _i55.Key? key;

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
/// [_i22.TenantAdminAccountsListRoutePage]
class TenantAdminAccountsListRoute extends _i54.PageRouteInfo<void> {
  const TenantAdminAccountsListRoute({List<_i54.PageRouteInfo>? children})
      : super(TenantAdminAccountsListRoute.name, initialChildren: children);

  static const String name = 'TenantAdminAccountsListRoute';

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      return const _i22.TenantAdminAccountsListRoutePage();
    },
  );
}

/// generated route for
/// [_i23.TenantAdminDashboardRoutePage]
class TenantAdminDashboardRoute extends _i54.PageRouteInfo<void> {
  const TenantAdminDashboardRoute({List<_i54.PageRouteInfo>? children})
      : super(TenantAdminDashboardRoute.name, initialChildren: children);

  static const String name = 'TenantAdminDashboardRoute';

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      return const _i23.TenantAdminDashboardRoutePage();
    },
  );
}

/// generated route for
/// [_i24.TenantAdminEventsRoutePage]
class TenantAdminEventsRoute extends _i54.PageRouteInfo<void> {
  const TenantAdminEventsRoute({List<_i54.PageRouteInfo>? children})
      : super(TenantAdminEventsRoute.name, initialChildren: children);

  static const String name = 'TenantAdminEventsRoute';

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      return const _i24.TenantAdminEventsRoutePage();
    },
  );
}

/// generated route for
/// [_i25.TenantAdminLocationPickerScreen]
class TenantAdminLocationPickerRoute
    extends _i54.PageRouteInfo<TenantAdminLocationPickerRouteArgs> {
  TenantAdminLocationPickerRoute({
    _i55.Key? key,
    _i60.TenantAdminLocation? initialLocation,
    List<_i54.PageRouteInfo>? children,
  }) : super(
          TenantAdminLocationPickerRoute.name,
          args: TenantAdminLocationPickerRouteArgs(
            key: key,
            initialLocation: initialLocation,
          ),
          initialChildren: children,
        );

  static const String name = 'TenantAdminLocationPickerRoute';

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TenantAdminLocationPickerRouteArgs>(
        orElse: () => const TenantAdminLocationPickerRouteArgs(),
      );
      return _i25.TenantAdminLocationPickerScreen(
        key: args.key,
        initialLocation: args.initialLocation,
      );
    },
  );
}

class TenantAdminLocationPickerRouteArgs {
  const TenantAdminLocationPickerRouteArgs({this.key, this.initialLocation});

  final _i55.Key? key;

  final _i60.TenantAdminLocation? initialLocation;

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
/// [_i26.TenantAdminOrganizationCreateRoutePage]
class TenantAdminOrganizationCreateRoute extends _i54.PageRouteInfo<void> {
  const TenantAdminOrganizationCreateRoute({List<_i54.PageRouteInfo>? children})
      : super(TenantAdminOrganizationCreateRoute.name,
            initialChildren: children);

  static const String name = 'TenantAdminOrganizationCreateRoute';

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      return const _i26.TenantAdminOrganizationCreateRoutePage();
    },
  );
}

/// generated route for
/// [_i27.TenantAdminOrganizationDetailRoutePage]
class TenantAdminOrganizationDetailRoute
    extends _i54.PageRouteInfo<TenantAdminOrganizationDetailRouteArgs> {
  TenantAdminOrganizationDetailRoute({
    _i55.Key? key,
    required String organizationId,
    List<_i54.PageRouteInfo>? children,
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

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminOrganizationDetailRouteArgs>(
        orElse: () => TenantAdminOrganizationDetailRouteArgs(
          organizationId: pathParams.getString('organizationId'),
        ),
      );
      return _i27.TenantAdminOrganizationDetailRoutePage(
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

  final _i55.Key? key;

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
/// [_i28.TenantAdminOrganizationsListRoutePage]
class TenantAdminOrganizationsListRoute extends _i54.PageRouteInfo<void> {
  const TenantAdminOrganizationsListRoute({List<_i54.PageRouteInfo>? children})
      : super(TenantAdminOrganizationsListRoute.name,
            initialChildren: children);

  static const String name = 'TenantAdminOrganizationsListRoute';

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      return const _i28.TenantAdminOrganizationsListRoutePage();
    },
  );
}

/// generated route for
/// [_i29.TenantAdminProfileTypeCreateRoutePage]
class TenantAdminProfileTypeCreateRoute extends _i54.PageRouteInfo<void> {
  const TenantAdminProfileTypeCreateRoute({List<_i54.PageRouteInfo>? children})
      : super(TenantAdminProfileTypeCreateRoute.name,
            initialChildren: children);

  static const String name = 'TenantAdminProfileTypeCreateRoute';

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      return const _i29.TenantAdminProfileTypeCreateRoutePage();
    },
  );
}

/// generated route for
/// [_i30.TenantAdminProfileTypeDetailRoutePage]
class TenantAdminProfileTypeDetailRoute
    extends _i54.PageRouteInfo<TenantAdminProfileTypeDetailRouteArgs> {
  TenantAdminProfileTypeDetailRoute({
    _i55.Key? key,
    required String profileType,
    required _i61.TenantAdminProfileTypeDefinition definition,
    List<_i54.PageRouteInfo>? children,
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

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TenantAdminProfileTypeDetailRouteArgs>();
      return _i30.TenantAdminProfileTypeDetailRoutePage(
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

  final _i55.Key? key;

  final String profileType;

  final _i61.TenantAdminProfileTypeDefinition definition;

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
/// [_i31.TenantAdminProfileTypeEditRoutePage]
class TenantAdminProfileTypeEditRoute
    extends _i54.PageRouteInfo<TenantAdminProfileTypeEditRouteArgs> {
  TenantAdminProfileTypeEditRoute({
    _i55.Key? key,
    required String profileType,
    required _i61.TenantAdminProfileTypeDefinition definition,
    List<_i54.PageRouteInfo>? children,
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

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TenantAdminProfileTypeEditRouteArgs>();
      return _i31.TenantAdminProfileTypeEditRoutePage(
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

  final _i55.Key? key;

  final String profileType;

  final _i61.TenantAdminProfileTypeDefinition definition;

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
/// [_i32.TenantAdminProfileTypesListRoutePage]
class TenantAdminProfileTypesListRoute extends _i54.PageRouteInfo<void> {
  const TenantAdminProfileTypesListRoute({List<_i54.PageRouteInfo>? children})
      : super(TenantAdminProfileTypesListRoute.name, initialChildren: children);

  static const String name = 'TenantAdminProfileTypesListRoute';

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      return const _i32.TenantAdminProfileTypesListRoutePage();
    },
  );
}

/// generated route for
/// [_i33.TenantAdminSettingsEnvironmentSnapshotRoutePage]
class TenantAdminSettingsEnvironmentSnapshotRoute
    extends _i54.PageRouteInfo<void> {
  const TenantAdminSettingsEnvironmentSnapshotRoute({
    List<_i54.PageRouteInfo>? children,
  }) : super(
          TenantAdminSettingsEnvironmentSnapshotRoute.name,
          initialChildren: children,
        );

  static const String name = 'TenantAdminSettingsEnvironmentSnapshotRoute';

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      return const _i33.TenantAdminSettingsEnvironmentSnapshotRoutePage();
    },
  );
}

/// generated route for
/// [_i34.TenantAdminSettingsLocalPreferencesRoutePage]
class TenantAdminSettingsLocalPreferencesRoute
    extends _i54.PageRouteInfo<void> {
  const TenantAdminSettingsLocalPreferencesRoute({
    List<_i54.PageRouteInfo>? children,
  }) : super(
          TenantAdminSettingsLocalPreferencesRoute.name,
          initialChildren: children,
        );

  static const String name = 'TenantAdminSettingsLocalPreferencesRoute';

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      return const _i34.TenantAdminSettingsLocalPreferencesRoutePage();
    },
  );
}

/// generated route for
/// [_i35.TenantAdminSettingsRoutePage]
class TenantAdminSettingsRoute extends _i54.PageRouteInfo<void> {
  const TenantAdminSettingsRoute({List<_i54.PageRouteInfo>? children})
      : super(TenantAdminSettingsRoute.name, initialChildren: children);

  static const String name = 'TenantAdminSettingsRoute';

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      return const _i35.TenantAdminSettingsRoutePage();
    },
  );
}

/// generated route for
/// [_i36.TenantAdminSettingsTechnicalIntegrationsRoutePage]
class TenantAdminSettingsTechnicalIntegrationsRoute extends _i54
    .PageRouteInfo<TenantAdminSettingsTechnicalIntegrationsRouteArgs> {
  TenantAdminSettingsTechnicalIntegrationsRoute({
    _i55.Key? key,
    _i62.TenantAdminSettingsIntegrationSection initialSection =
        _i62.TenantAdminSettingsIntegrationSection.firebase,
    List<_i54.PageRouteInfo>? children,
  }) : super(
          TenantAdminSettingsTechnicalIntegrationsRoute.name,
          args: TenantAdminSettingsTechnicalIntegrationsRouteArgs(
            key: key,
            initialSection: initialSection,
          ),
          initialChildren: children,
        );

  static const String name = 'TenantAdminSettingsTechnicalIntegrationsRoute';

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      final args =
          data.argsAs<TenantAdminSettingsTechnicalIntegrationsRouteArgs>(
        orElse: () => const TenantAdminSettingsTechnicalIntegrationsRouteArgs(),
      );
      return _i36.TenantAdminSettingsTechnicalIntegrationsRoutePage(
        key: args.key,
        initialSection: args.initialSection,
      );
    },
  );
}

class TenantAdminSettingsTechnicalIntegrationsRouteArgs {
  const TenantAdminSettingsTechnicalIntegrationsRouteArgs({
    this.key,
    this.initialSection = _i62.TenantAdminSettingsIntegrationSection.firebase,
  });

  final _i55.Key? key;

  final _i62.TenantAdminSettingsIntegrationSection initialSection;

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
/// [_i37.TenantAdminSettingsVisualIdentityRoutePage]
class TenantAdminSettingsVisualIdentityRoute extends _i54.PageRouteInfo<void> {
  const TenantAdminSettingsVisualIdentityRoute({
    List<_i54.PageRouteInfo>? children,
  }) : super(
          TenantAdminSettingsVisualIdentityRoute.name,
          initialChildren: children,
        );

  static const String name = 'TenantAdminSettingsVisualIdentityRoute';

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      return const _i37.TenantAdminSettingsVisualIdentityRoutePage();
    },
  );
}

/// generated route for
/// [_i38.TenantAdminShellRoutePage]
class TenantAdminShellRoute extends _i54.PageRouteInfo<void> {
  const TenantAdminShellRoute({List<_i54.PageRouteInfo>? children})
      : super(TenantAdminShellRoute.name, initialChildren: children);

  static const String name = 'TenantAdminShellRoute';

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      return const _i38.TenantAdminShellRoutePage();
    },
  );
}

/// generated route for
/// [_i39.TenantAdminStaticAssetCreateRoutePage]
class TenantAdminStaticAssetCreateRoute extends _i54.PageRouteInfo<void> {
  const TenantAdminStaticAssetCreateRoute({List<_i54.PageRouteInfo>? children})
      : super(TenantAdminStaticAssetCreateRoute.name,
            initialChildren: children);

  static const String name = 'TenantAdminStaticAssetCreateRoute';

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      return const _i39.TenantAdminStaticAssetCreateRoutePage();
    },
  );
}

/// generated route for
/// [_i40.TenantAdminStaticAssetDetailRoutePage]
class TenantAdminStaticAssetDetailRoute
    extends _i54.PageRouteInfo<TenantAdminStaticAssetDetailRouteArgs> {
  TenantAdminStaticAssetDetailRoute({
    _i55.Key? key,
    required String assetId,
    List<_i54.PageRouteInfo>? children,
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

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminStaticAssetDetailRouteArgs>(
        orElse: () => TenantAdminStaticAssetDetailRouteArgs(
          assetId: pathParams.getString('assetId'),
        ),
      );
      return _i40.TenantAdminStaticAssetDetailRoutePage(
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

  final _i55.Key? key;

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
/// [_i41.TenantAdminStaticAssetEditRoutePage]
class TenantAdminStaticAssetEditRoute
    extends _i54.PageRouteInfo<TenantAdminStaticAssetEditRouteArgs> {
  TenantAdminStaticAssetEditRoute({
    _i55.Key? key,
    required String assetId,
    List<_i54.PageRouteInfo>? children,
  }) : super(
          TenantAdminStaticAssetEditRoute.name,
          args: TenantAdminStaticAssetEditRouteArgs(key: key, assetId: assetId),
          rawPathParams: {'assetId': assetId},
          initialChildren: children,
        );

  static const String name = 'TenantAdminStaticAssetEditRoute';

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TenantAdminStaticAssetEditRouteArgs>(
        orElse: () => TenantAdminStaticAssetEditRouteArgs(
          assetId: pathParams.getString('assetId'),
        ),
      );
      return _i41.TenantAdminStaticAssetEditRoutePage(
        key: args.key,
        assetId: args.assetId,
      );
    },
  );
}

class TenantAdminStaticAssetEditRouteArgs {
  const TenantAdminStaticAssetEditRouteArgs({this.key, required this.assetId});

  final _i55.Key? key;

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
/// [_i42.TenantAdminStaticAssetsListRoutePage]
class TenantAdminStaticAssetsListRoute extends _i54.PageRouteInfo<void> {
  const TenantAdminStaticAssetsListRoute({List<_i54.PageRouteInfo>? children})
      : super(TenantAdminStaticAssetsListRoute.name, initialChildren: children);

  static const String name = 'TenantAdminStaticAssetsListRoute';

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      return const _i42.TenantAdminStaticAssetsListRoutePage();
    },
  );
}

/// generated route for
/// [_i43.TenantAdminStaticProfileTypeCreateRoutePage]
class TenantAdminStaticProfileTypeCreateRoute extends _i54.PageRouteInfo<void> {
  const TenantAdminStaticProfileTypeCreateRoute({
    List<_i54.PageRouteInfo>? children,
  }) : super(
          TenantAdminStaticProfileTypeCreateRoute.name,
          initialChildren: children,
        );

  static const String name = 'TenantAdminStaticProfileTypeCreateRoute';

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      return const _i43.TenantAdminStaticProfileTypeCreateRoutePage();
    },
  );
}

/// generated route for
/// [_i44.TenantAdminStaticProfileTypeDetailRoutePage]
class TenantAdminStaticProfileTypeDetailRoute
    extends _i54.PageRouteInfo<TenantAdminStaticProfileTypeDetailRouteArgs> {
  TenantAdminStaticProfileTypeDetailRoute({
    _i55.Key? key,
    required String profileType,
    required _i63.TenantAdminStaticProfileTypeDefinition definition,
    List<_i54.PageRouteInfo>? children,
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

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TenantAdminStaticProfileTypeDetailRouteArgs>();
      return _i44.TenantAdminStaticProfileTypeDetailRoutePage(
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

  final _i55.Key? key;

  final String profileType;

  final _i63.TenantAdminStaticProfileTypeDefinition definition;

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
/// [_i45.TenantAdminStaticProfileTypeEditRoutePage]
class TenantAdminStaticProfileTypeEditRoute
    extends _i54.PageRouteInfo<TenantAdminStaticProfileTypeEditRouteArgs> {
  TenantAdminStaticProfileTypeEditRoute({
    _i55.Key? key,
    required String profileType,
    required _i63.TenantAdminStaticProfileTypeDefinition definition,
    List<_i54.PageRouteInfo>? children,
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

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TenantAdminStaticProfileTypeEditRouteArgs>();
      return _i45.TenantAdminStaticProfileTypeEditRoutePage(
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

  final _i55.Key? key;

  final String profileType;

  final _i63.TenantAdminStaticProfileTypeDefinition definition;

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
/// [_i46.TenantAdminStaticProfileTypesListRoutePage]
class TenantAdminStaticProfileTypesListRoute extends _i54.PageRouteInfo<void> {
  const TenantAdminStaticProfileTypesListRoute({
    List<_i54.PageRouteInfo>? children,
  }) : super(
          TenantAdminStaticProfileTypesListRoute.name,
          initialChildren: children,
        );

  static const String name = 'TenantAdminStaticProfileTypesListRoute';

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      return const _i46.TenantAdminStaticProfileTypesListRoutePage();
    },
  );
}

/// generated route for
/// [_i47.TenantAdminTaxonomiesListRoutePage]
class TenantAdminTaxonomiesListRoute extends _i54.PageRouteInfo<void> {
  const TenantAdminTaxonomiesListRoute({List<_i54.PageRouteInfo>? children})
      : super(TenantAdminTaxonomiesListRoute.name, initialChildren: children);

  static const String name = 'TenantAdminTaxonomiesListRoute';

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      return const _i47.TenantAdminTaxonomiesListRoutePage();
    },
  );
}

/// generated route for
/// [_i48.TenantAdminTaxonomyCreateRoutePage]
class TenantAdminTaxonomyCreateRoute extends _i54.PageRouteInfo<void> {
  const TenantAdminTaxonomyCreateRoute({List<_i54.PageRouteInfo>? children})
      : super(TenantAdminTaxonomyCreateRoute.name, initialChildren: children);

  static const String name = 'TenantAdminTaxonomyCreateRoute';

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      return const _i48.TenantAdminTaxonomyCreateRoutePage();
    },
  );
}

/// generated route for
/// [_i48.TenantAdminTaxonomyEditRoutePage]
class TenantAdminTaxonomyEditRoute
    extends _i54.PageRouteInfo<TenantAdminTaxonomyEditRouteArgs> {
  TenantAdminTaxonomyEditRoute({
    _i55.Key? key,
    required String taxonomyId,
    required _i64.TenantAdminTaxonomyDefinition taxonomy,
    List<_i54.PageRouteInfo>? children,
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

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TenantAdminTaxonomyEditRouteArgs>();
      return _i48.TenantAdminTaxonomyEditRoutePage(
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

  final _i55.Key? key;

  final String taxonomyId;

  final _i64.TenantAdminTaxonomyDefinition taxonomy;

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
/// [_i49.TenantAdminTaxonomyTermCreateRoutePage]
class TenantAdminTaxonomyTermCreateRoute
    extends _i54.PageRouteInfo<TenantAdminTaxonomyTermCreateRouteArgs> {
  TenantAdminTaxonomyTermCreateRoute({
    _i55.Key? key,
    required String taxonomyId,
    required String taxonomyName,
    List<_i54.PageRouteInfo>? children,
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

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TenantAdminTaxonomyTermCreateRouteArgs>();
      return _i49.TenantAdminTaxonomyTermCreateRoutePage(
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

  final _i55.Key? key;

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
/// [_i50.TenantAdminTaxonomyTermDetailRoutePage]
class TenantAdminTaxonomyTermDetailRoute
    extends _i54.PageRouteInfo<TenantAdminTaxonomyTermDetailRouteArgs> {
  TenantAdminTaxonomyTermDetailRoute({
    _i55.Key? key,
    required String taxonomyId,
    required String taxonomyName,
    required String termId,
    required _i65.TenantAdminTaxonomyTermDefinition term,
    List<_i54.PageRouteInfo>? children,
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

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TenantAdminTaxonomyTermDetailRouteArgs>();
      return _i50.TenantAdminTaxonomyTermDetailRoutePage(
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

  final _i55.Key? key;

  final String taxonomyId;

  final String taxonomyName;

  final String termId;

  final _i65.TenantAdminTaxonomyTermDefinition term;

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
/// [_i49.TenantAdminTaxonomyTermEditRoutePage]
class TenantAdminTaxonomyTermEditRoute
    extends _i54.PageRouteInfo<TenantAdminTaxonomyTermEditRouteArgs> {
  TenantAdminTaxonomyTermEditRoute({
    _i55.Key? key,
    required String taxonomyId,
    required String taxonomyName,
    required String termId,
    required _i65.TenantAdminTaxonomyTermDefinition term,
    List<_i54.PageRouteInfo>? children,
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

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TenantAdminTaxonomyTermEditRouteArgs>();
      return _i49.TenantAdminTaxonomyTermEditRoutePage(
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

  final _i55.Key? key;

  final String taxonomyId;

  final String taxonomyName;

  final String termId;

  final _i65.TenantAdminTaxonomyTermDefinition term;

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
/// [_i51.TenantAdminTaxonomyTermsRoutePage]
class TenantAdminTaxonomyTermsRoute
    extends _i54.PageRouteInfo<TenantAdminTaxonomyTermsRouteArgs> {
  TenantAdminTaxonomyTermsRoute({
    _i55.Key? key,
    required String taxonomyId,
    required String taxonomyName,
    List<_i54.PageRouteInfo>? children,
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

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TenantAdminTaxonomyTermsRouteArgs>();
      return _i51.TenantAdminTaxonomyTermsRoutePage(
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

  final _i55.Key? key;

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
/// [_i52.TenantHomeRoutePage]
class TenantHomeRoute extends _i54.PageRouteInfo<void> {
  const TenantHomeRoute({List<_i54.PageRouteInfo>? children})
      : super(TenantHomeRoute.name, initialChildren: children);

  static const String name = 'TenantHomeRoute';

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      return const _i52.TenantHomeRoutePage();
    },
  );
}

/// generated route for
/// [_i53.TenantMenuRoutePage]
class TenantMenuRoute extends _i54.PageRouteInfo<void> {
  const TenantMenuRoute({List<_i54.PageRouteInfo>? children})
      : super(TenantMenuRoute.name, initialChildren: children);

  static const String name = 'TenantMenuRoute';

  static _i54.PageInfo page = _i54.PageInfo(
    name,
    builder: (data) {
      return const _i53.TenantMenuRoutePage();
    },
  );
}
