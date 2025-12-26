// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i21;
import 'package:belluga_now/application/router/guards/location_permission_state.dart'
    as _i25;
import 'package:belluga_now/domain/invites/invite_model.dart' as _i24;
import 'package:belluga_now/domain/map/city_poi_model.dart' as _i26;
import 'package:belluga_now/presentation/common/auth/routes/auth_create_new_password_route.dart'
    as _i1;
import 'package:belluga_now/presentation/common/auth/routes/auth_login_route.dart'
    as _i2;
import 'package:belluga_now/presentation/common/auth/routes/recovery_password_route.dart'
    as _i18;
import 'package:belluga_now/presentation/common/init/routes/init_route.dart'
    as _i8;
import 'package:belluga_now/presentation/common/location_permission/routes/location_not_live_route.dart'
    as _i12;
import 'package:belluga_now/presentation/common/location_permission/routes/location_permission_route.dart'
    as _i13;
import 'package:belluga_now/presentation/landlord/home/routes/landlord_home_route.dart'
    as _i11;
import 'package:belluga_now/presentation/prototypes/map_experience/routes/map_experience_prototype_route.dart'
    as _i14;
import 'package:belluga_now/presentation/tenant/discovery/routes/discovery_route.dart'
    as _i4;
import 'package:belluga_now/presentation/tenant/home/routes/tenant_home_route.dart'
    as _i19;
import 'package:belluga_now/presentation/tenant/invites/routes/invite_flow_route.dart'
    as _i9;
import 'package:belluga_now/presentation/tenant/invites/routes/invite_share_route.dart'
    as _i10;
import 'package:belluga_now/presentation/tenant/map/routes/city_map_route.dart'
    as _i3;
import 'package:belluga_now/presentation/tenant/map/routes/poi_details_route.dart'
    as _i16;
import 'package:belluga_now/presentation/tenant/menu/routes/tenant_menu_route.dart'
    as _i20;
import 'package:belluga_now/presentation/tenant/partners/routes/partner_detail_route.dart'
    as _i15;
import 'package:belluga_now/presentation/tenant/profile/routes/profile_route.dart'
    as _i17;
import 'package:belluga_now/presentation/tenant/schedule/routes/event_detail_route.dart'
    as _i5;
import 'package:belluga_now/presentation/tenant/schedule/routes/event_search_route.dart'
    as _i6;
import 'package:belluga_now/presentation/tenant/schedule/routes/immersive_event_detail_route.dart'
    as _i7;
import 'package:belluga_now/presentation/tenant/schedule/screens/event_search_screen/models/invite_filter.dart'
    as _i23;
import 'package:flutter/material.dart' as _i22;

/// generated route for
/// [_i1.AuthCreateNewPasswordRoutePage]
class AuthCreateNewPasswordRoute extends _i21.PageRouteInfo<void> {
  const AuthCreateNewPasswordRoute({List<_i21.PageRouteInfo>? children})
      : super(AuthCreateNewPasswordRoute.name, initialChildren: children);

  static const String name = 'AuthCreateNewPasswordRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return const _i1.AuthCreateNewPasswordRoutePage();
    },
  );
}

/// generated route for
/// [_i2.AuthLoginRoutePage]
class AuthLoginRoute extends _i21.PageRouteInfo<void> {
  const AuthLoginRoute({List<_i21.PageRouteInfo>? children})
      : super(AuthLoginRoute.name, initialChildren: children);

  static const String name = 'AuthLoginRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return const _i2.AuthLoginRoutePage();
    },
  );
}

/// generated route for
/// [_i3.CityMapRoutePage]
class CityMapRoute extends _i21.PageRouteInfo<void> {
  const CityMapRoute({List<_i21.PageRouteInfo>? children})
      : super(CityMapRoute.name, initialChildren: children);

  static const String name = 'CityMapRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return const _i3.CityMapRoutePage();
    },
  );
}

/// generated route for
/// [_i4.DiscoveryRoute]
class DiscoveryRoute extends _i21.PageRouteInfo<void> {
  const DiscoveryRoute({List<_i21.PageRouteInfo>? children})
      : super(DiscoveryRoute.name, initialChildren: children);

  static const String name = 'DiscoveryRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return const _i4.DiscoveryRoute();
    },
  );
}

/// generated route for
/// [_i5.EventDetailRoutePage]
class EventDetailRoute extends _i21.PageRouteInfo<EventDetailRouteArgs> {
  EventDetailRoute({
    _i22.Key? key,
    required String slug,
    List<_i21.PageRouteInfo>? children,
  }) : super(
          EventDetailRoute.name,
          args: EventDetailRouteArgs(key: key, slug: slug),
          rawPathParams: {'slug': slug},
          initialChildren: children,
        );

  static const String name = 'EventDetailRoute';

  static _i21.PageInfo page = _i21.PageInfo(
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

  final _i22.Key? key;

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
class EventSearchRoute extends _i21.PageRouteInfo<EventSearchRouteArgs> {
  EventSearchRoute({
    _i22.Key? key,
    bool startSearchActive = false,
    String? initialSearchQuery,
    _i23.InviteFilter inviteFilter = _i23.InviteFilter.none,
    bool startWithHistory = false,
    List<_i21.PageRouteInfo>? children,
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

  static _i21.PageInfo page = _i21.PageInfo(
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
    this.inviteFilter = _i23.InviteFilter.none,
    this.startWithHistory = false,
  });

  final _i22.Key? key;

  final bool startSearchActive;

  final String? initialSearchQuery;

  final _i23.InviteFilter inviteFilter;

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
    extends _i21.PageRouteInfo<ImmersiveEventDetailRouteArgs> {
  ImmersiveEventDetailRoute({
    _i22.Key? key,
    required String eventSlug,
    List<_i21.PageRouteInfo>? children,
  }) : super(
          ImmersiveEventDetailRoute.name,
          args: ImmersiveEventDetailRouteArgs(key: key, eventSlug: eventSlug),
          rawPathParams: {'slug': eventSlug},
          initialChildren: children,
        );

  static const String name = 'ImmersiveEventDetailRoute';

  static _i21.PageInfo page = _i21.PageInfo(
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

  final _i22.Key? key;

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
class InitRoute extends _i21.PageRouteInfo<void> {
  const InitRoute({List<_i21.PageRouteInfo>? children})
      : super(InitRoute.name, initialChildren: children);

  static const String name = 'InitRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return const _i8.InitRoutePage();
    },
  );
}

/// generated route for
/// [_i9.InviteFlowRoutePage]
class InviteFlowRoute extends _i21.PageRouteInfo<void> {
  const InviteFlowRoute({List<_i21.PageRouteInfo>? children})
      : super(InviteFlowRoute.name, initialChildren: children);

  static const String name = 'InviteFlowRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return const _i9.InviteFlowRoutePage();
    },
  );
}

/// generated route for
/// [_i10.InviteShareRoutePage]
class InviteShareRoute extends _i21.PageRouteInfo<InviteShareRouteArgs> {
  InviteShareRoute({
    _i22.Key? key,
    required _i24.InviteModel invite,
    List<_i21.PageRouteInfo>? children,
  }) : super(
          InviteShareRoute.name,
          args: InviteShareRouteArgs(key: key, invite: invite),
          initialChildren: children,
        );

  static const String name = 'InviteShareRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<InviteShareRouteArgs>();
      return _i10.InviteShareRoutePage(key: args.key, invite: args.invite);
    },
  );
}

class InviteShareRouteArgs {
  const InviteShareRouteArgs({this.key, required this.invite});

  final _i22.Key? key;

  final _i24.InviteModel invite;

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
class LandlordHomeRoute extends _i21.PageRouteInfo<void> {
  const LandlordHomeRoute({List<_i21.PageRouteInfo>? children})
      : super(LandlordHomeRoute.name, initialChildren: children);

  static const String name = 'LandlordHomeRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return const _i11.LandlordHomeRoutePage();
    },
  );
}

/// generated route for
/// [_i12.LocationNotLiveRoutePage]
class LocationNotLiveRoute
    extends _i21.PageRouteInfo<LocationNotLiveRouteArgs> {
  LocationNotLiveRoute({
    _i22.Key? key,
    required _i25.LocationPermissionState blockerState,
    String? addressLabel,
    DateTime? capturedAt,
    List<_i21.PageRouteInfo>? children,
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

  static _i21.PageInfo page = _i21.PageInfo(
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

  final _i22.Key? key;

  final _i25.LocationPermissionState blockerState;

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
    extends _i21.PageRouteInfo<LocationPermissionRouteArgs> {
  LocationPermissionRoute({
    _i22.Key? key,
    required _i25.LocationPermissionState initialState,
    List<_i21.PageRouteInfo>? children,
  }) : super(
          LocationPermissionRoute.name,
          args: LocationPermissionRouteArgs(
            key: key,
            initialState: initialState,
          ),
          initialChildren: children,
        );

  static const String name = 'LocationPermissionRoute';

  static _i21.PageInfo page = _i21.PageInfo(
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

  final _i22.Key? key;

  final _i25.LocationPermissionState initialState;

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
/// [_i14.MapExperiencePrototypeRoutePage]
class MapExperiencePrototypeRoute extends _i21.PageRouteInfo<void> {
  const MapExperiencePrototypeRoute({List<_i21.PageRouteInfo>? children})
      : super(MapExperiencePrototypeRoute.name, initialChildren: children);

  static const String name = 'MapExperiencePrototypeRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return const _i14.MapExperiencePrototypeRoutePage();
    },
  );
}

/// generated route for
/// [_i15.PartnerDetailRoute]
class PartnerDetailRoute extends _i21.PageRouteInfo<PartnerDetailRouteArgs> {
  PartnerDetailRoute({
    _i22.Key? key,
    required String slug,
    List<_i21.PageRouteInfo>? children,
  }) : super(
          PartnerDetailRoute.name,
          args: PartnerDetailRouteArgs(key: key, slug: slug),
          rawPathParams: {'slug': slug},
          initialChildren: children,
        );

  static const String name = 'PartnerDetailRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<PartnerDetailRouteArgs>(
        orElse: () =>
            PartnerDetailRouteArgs(slug: pathParams.getString('slug')),
      );
      return _i15.PartnerDetailRoute(key: args.key, slug: args.slug);
    },
  );
}

class PartnerDetailRouteArgs {
  const PartnerDetailRouteArgs({this.key, required this.slug});

  final _i22.Key? key;

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
/// [_i16.PoiDetailsRoutePage]
class PoiDetailsRoute extends _i21.PageRouteInfo<PoiDetailsRouteArgs> {
  PoiDetailsRoute({
    _i22.Key? key,
    required _i26.CityPoiModel poi,
    List<_i21.PageRouteInfo>? children,
  }) : super(
          PoiDetailsRoute.name,
          args: PoiDetailsRouteArgs(key: key, poi: poi),
          initialChildren: children,
        );

  static const String name = 'PoiDetailsRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PoiDetailsRouteArgs>();
      return _i16.PoiDetailsRoutePage(key: args.key, poi: args.poi);
    },
  );
}

class PoiDetailsRouteArgs {
  const PoiDetailsRouteArgs({this.key, required this.poi});

  final _i22.Key? key;

  final _i26.CityPoiModel poi;

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
/// [_i17.ProfileRoutePage]
class ProfileRoute extends _i21.PageRouteInfo<void> {
  const ProfileRoute({List<_i21.PageRouteInfo>? children})
      : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return const _i17.ProfileRoutePage();
    },
  );
}

/// generated route for
/// [_i18.RecoveryPasswordRoutePage]
class RecoveryPasswordRoute
    extends _i21.PageRouteInfo<RecoveryPasswordRouteArgs> {
  RecoveryPasswordRoute({
    _i22.Key? key,
    String? initialEmmail,
    List<_i21.PageRouteInfo>? children,
  }) : super(
          RecoveryPasswordRoute.name,
          args: RecoveryPasswordRouteArgs(
            key: key,
            initialEmmail: initialEmmail,
          ),
          initialChildren: children,
        );

  static const String name = 'RecoveryPasswordRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RecoveryPasswordRouteArgs>(
        orElse: () => const RecoveryPasswordRouteArgs(),
      );
      return _i18.RecoveryPasswordRoutePage(
        key: args.key,
        initialEmmail: args.initialEmmail,
      );
    },
  );
}

class RecoveryPasswordRouteArgs {
  const RecoveryPasswordRouteArgs({this.key, this.initialEmmail});

  final _i22.Key? key;

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
/// [_i19.TenantHomeRoutePage]
class TenantHomeRoute extends _i21.PageRouteInfo<void> {
  const TenantHomeRoute({List<_i21.PageRouteInfo>? children})
      : super(TenantHomeRoute.name, initialChildren: children);

  static const String name = 'TenantHomeRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return const _i19.TenantHomeRoutePage();
    },
  );
}

/// generated route for
/// [_i20.TenantMenuRoutePage]
class TenantMenuRoute extends _i21.PageRouteInfo<void> {
  const TenantMenuRoute({List<_i21.PageRouteInfo>? children})
      : super(TenantMenuRoute.name, initialChildren: children);

  static const String name = 'TenantMenuRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return const _i20.TenantMenuRoutePage();
    },
  );
}
