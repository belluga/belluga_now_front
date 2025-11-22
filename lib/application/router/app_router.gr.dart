// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i24;
import 'package:belluga_now/domain/experiences/experience_model.dart' as _i26;
import 'package:belluga_now/domain/invites/invite_model.dart' as _i27;
import 'package:belluga_now/domain/map/city_poi_model.dart' as _i28;
import 'package:belluga_now/presentation/common/auth/routes/auth_create_new_password_route.dart'
    as _i1;
import 'package:belluga_now/presentation/common/auth/routes/auth_login_route.dart'
    as _i2;
import 'package:belluga_now/presentation/common/auth/routes/recovery_password_route.dart'
    as _i19;
import 'package:belluga_now/presentation/common/init/routes/init_route.dart'
    as _i9;
import 'package:belluga_now/presentation/landlord/home/routes/landlord_home_route.dart'
    as _i12;
import 'package:belluga_now/presentation/prototypes/map_experience/routes/map_experience_prototype_route.dart'
    as _i13;
import 'package:belluga_now/presentation/tenant/discovery/routes/discovery_route.dart'
    as _i4;
import 'package:belluga_now/presentation/tenant/experiences/routes/experience_detail_route.dart'
    as _i7;
import 'package:belluga_now/presentation/tenant/experiences/routes/experiences_route.dart'
    as _i8;
import 'package:belluga_now/presentation/tenant/home/routes/tenant_home_route.dart'
    as _i21;
import 'package:belluga_now/presentation/tenant/invites/routes/invite_flow_route.dart'
    as _i10;
import 'package:belluga_now/presentation/tenant/invites/routes/invite_share_route.dart'
    as _i11;
import 'package:belluga_now/presentation/tenant/map/routes/city_map_route.dart'
    as _i3;
import 'package:belluga_now/presentation/tenant/map/routes/poi_details_route.dart'
    as _i16;
import 'package:belluga_now/presentation/tenant/menu/routes/tenant_menu_route.dart'
    as _i22;
import 'package:belluga_now/presentation/tenant/mercado/models/mercado_producer.dart'
    as _i29;
import 'package:belluga_now/presentation/tenant/mercado/routes/mercado_route.dart'
    as _i14;
import 'package:belluga_now/presentation/tenant/mercado/routes/producer_store_route.dart'
    as _i17;
import 'package:belluga_now/presentation/tenant/partners/routes/partner_detail_route.dart'
    as _i15;
import 'package:belluga_now/presentation/tenant/profile/routes/profile_route.dart'
    as _i18;
import 'package:belluga_now/presentation/tenant/schedule/routes/event_detail_route.dart'
    as _i5;
import 'package:belluga_now/presentation/tenant/schedule/routes/event_search_route.dart'
    as _i6;
import 'package:belluga_now/presentation/tenant/schedule/routes/schedule_route.dart'
    as _i20;
import 'package:belluga_now/presentation/tenant/tabs/tenant_tabs_route.dart'
    as _i23;
import 'package:flutter/material.dart' as _i25;

/// generated route for
/// [_i1.AuthCreateNewPasswordRoutePage]
class AuthCreateNewPasswordRoute extends _i24.PageRouteInfo<void> {
  const AuthCreateNewPasswordRoute({List<_i24.PageRouteInfo>? children})
      : super(AuthCreateNewPasswordRoute.name, initialChildren: children);

  static const String name = 'AuthCreateNewPasswordRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i1.AuthCreateNewPasswordRoutePage();
    },
  );
}

/// generated route for
/// [_i2.AuthLoginRoutePage]
class AuthLoginRoute extends _i24.PageRouteInfo<void> {
  const AuthLoginRoute({List<_i24.PageRouteInfo>? children})
      : super(AuthLoginRoute.name, initialChildren: children);

  static const String name = 'AuthLoginRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i2.AuthLoginRoutePage();
    },
  );
}

/// generated route for
/// [_i3.CityMapRoutePage]
class CityMapRoute extends _i24.PageRouteInfo<void> {
  const CityMapRoute({List<_i24.PageRouteInfo>? children})
      : super(CityMapRoute.name, initialChildren: children);

  static const String name = 'CityMapRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i3.CityMapRoutePage();
    },
  );
}

/// generated route for
/// [_i4.DiscoveryRoute]
class DiscoveryRoute extends _i24.PageRouteInfo<void> {
  const DiscoveryRoute({List<_i24.PageRouteInfo>? children})
      : super(DiscoveryRoute.name, initialChildren: children);

  static const String name = 'DiscoveryRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i4.DiscoveryRoute();
    },
  );
}

/// generated route for
/// [_i5.EventDetailRoutePage]
class EventDetailRoute extends _i24.PageRouteInfo<EventDetailRouteArgs> {
  EventDetailRoute({
    _i25.Key? key,
    required String slug,
    List<_i24.PageRouteInfo>? children,
  }) : super(
          EventDetailRoute.name,
          args: EventDetailRouteArgs(key: key, slug: slug),
          rawPathParams: {'slug': slug},
          initialChildren: children,
        );

  static const String name = 'EventDetailRoute';

  static _i24.PageInfo page = _i24.PageInfo(
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

  final _i25.Key? key;

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
class EventSearchRoute extends _i24.PageRouteInfo<void> {
  const EventSearchRoute({List<_i24.PageRouteInfo>? children})
      : super(EventSearchRoute.name, initialChildren: children);

  static const String name = 'EventSearchRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i6.EventSearchRoute();
    },
  );
}

/// generated route for
/// [_i7.ExperienceDetailRoutePage]
class ExperienceDetailRoute
    extends _i24.PageRouteInfo<ExperienceDetailRouteArgs> {
  ExperienceDetailRoute({
    _i25.Key? key,
    required _i26.ExperienceModel experience,
    List<_i24.PageRouteInfo>? children,
  }) : super(
          ExperienceDetailRoute.name,
          args: ExperienceDetailRouteArgs(key: key, experience: experience),
          initialChildren: children,
        );

  static const String name = 'ExperienceDetailRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ExperienceDetailRouteArgs>();
      return _i7.ExperienceDetailRoutePage(
        key: args.key,
        experience: args.experience,
      );
    },
  );
}

class ExperienceDetailRouteArgs {
  const ExperienceDetailRouteArgs({this.key, required this.experience});

  final _i25.Key? key;

  final _i26.ExperienceModel experience;

  @override
  String toString() {
    return 'ExperienceDetailRouteArgs{key: $key, experience: $experience}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ExperienceDetailRouteArgs) return false;
    return key == other.key && experience == other.experience;
  }

  @override
  int get hashCode => key.hashCode ^ experience.hashCode;
}

/// generated route for
/// [_i8.ExperiencesRoutePage]
class ExperiencesRoute extends _i24.PageRouteInfo<void> {
  const ExperiencesRoute({List<_i24.PageRouteInfo>? children})
      : super(ExperiencesRoute.name, initialChildren: children);

  static const String name = 'ExperiencesRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i8.ExperiencesRoutePage();
    },
  );
}

/// generated route for
/// [_i9.InitRoutePage]
class InitRoute extends _i24.PageRouteInfo<void> {
  const InitRoute({List<_i24.PageRouteInfo>? children})
      : super(InitRoute.name, initialChildren: children);

  static const String name = 'InitRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i9.InitRoutePage();
    },
  );
}

/// generated route for
/// [_i10.InviteFlowRoutePage]
class InviteFlowRoute extends _i24.PageRouteInfo<void> {
  const InviteFlowRoute({List<_i24.PageRouteInfo>? children})
      : super(InviteFlowRoute.name, initialChildren: children);

  static const String name = 'InviteFlowRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i10.InviteFlowRoutePage();
    },
  );
}

/// generated route for
/// [_i11.InviteShareRoutePage]
class InviteShareRoute extends _i24.PageRouteInfo<InviteShareRouteArgs> {
  InviteShareRoute({
    _i25.Key? key,
    required _i27.InviteModel invite,
    List<_i24.PageRouteInfo>? children,
  }) : super(
          InviteShareRoute.name,
          args: InviteShareRouteArgs(key: key, invite: invite),
          initialChildren: children,
        );

  static const String name = 'InviteShareRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<InviteShareRouteArgs>();
      return _i11.InviteShareRoutePage(key: args.key, invite: args.invite);
    },
  );
}

class InviteShareRouteArgs {
  const InviteShareRouteArgs({this.key, required this.invite});

  final _i25.Key? key;

  final _i27.InviteModel invite;

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
/// [_i12.LandlordHomeRoutePage]
class LandlordHomeRoute extends _i24.PageRouteInfo<void> {
  const LandlordHomeRoute({List<_i24.PageRouteInfo>? children})
      : super(LandlordHomeRoute.name, initialChildren: children);

  static const String name = 'LandlordHomeRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i12.LandlordHomeRoutePage();
    },
  );
}

/// generated route for
/// [_i13.MapExperiencePrototypeRoutePage]
class MapExperiencePrototypeRoute extends _i24.PageRouteInfo<void> {
  const MapExperiencePrototypeRoute({List<_i24.PageRouteInfo>? children})
      : super(MapExperiencePrototypeRoute.name, initialChildren: children);

  static const String name = 'MapExperiencePrototypeRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i13.MapExperiencePrototypeRoutePage();
    },
  );
}

/// generated route for
/// [_i14.MercadoRoutePage]
class MercadoRoute extends _i24.PageRouteInfo<void> {
  const MercadoRoute({List<_i24.PageRouteInfo>? children})
      : super(MercadoRoute.name, initialChildren: children);

  static const String name = 'MercadoRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i14.MercadoRoutePage();
    },
  );
}

/// generated route for
/// [_i15.PartnerDetailRoute]
class PartnerDetailRoute extends _i24.PageRouteInfo<PartnerDetailRouteArgs> {
  PartnerDetailRoute({
    _i25.Key? key,
    required String slug,
    List<_i24.PageRouteInfo>? children,
  }) : super(
          PartnerDetailRoute.name,
          args: PartnerDetailRouteArgs(key: key, slug: slug),
          rawPathParams: {'slug': slug},
          initialChildren: children,
        );

  static const String name = 'PartnerDetailRoute';

  static _i24.PageInfo page = _i24.PageInfo(
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

  final _i25.Key? key;

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
class PoiDetailsRoute extends _i24.PageRouteInfo<PoiDetailsRouteArgs> {
  PoiDetailsRoute({
    _i25.Key? key,
    required _i28.CityPoiModel poi,
    List<_i24.PageRouteInfo>? children,
  }) : super(
          PoiDetailsRoute.name,
          args: PoiDetailsRouteArgs(key: key, poi: poi),
          initialChildren: children,
        );

  static const String name = 'PoiDetailsRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PoiDetailsRouteArgs>();
      return _i16.PoiDetailsRoutePage(key: args.key, poi: args.poi);
    },
  );
}

class PoiDetailsRouteArgs {
  const PoiDetailsRouteArgs({this.key, required this.poi});

  final _i25.Key? key;

  final _i28.CityPoiModel poi;

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
/// [_i17.ProducerStoreRoutePage]
class ProducerStoreRoute extends _i24.PageRouteInfo<ProducerStoreRouteArgs> {
  ProducerStoreRoute({
    _i25.Key? key,
    required _i29.MercadoProducer producer,
    List<_i24.PageRouteInfo>? children,
  }) : super(
          ProducerStoreRoute.name,
          args: ProducerStoreRouteArgs(key: key, producer: producer),
          initialChildren: children,
        );

  static const String name = 'ProducerStoreRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ProducerStoreRouteArgs>();
      return _i17.ProducerStoreRoutePage(
        key: args.key,
        producer: args.producer,
      );
    },
  );
}

class ProducerStoreRouteArgs {
  const ProducerStoreRouteArgs({this.key, required this.producer});

  final _i25.Key? key;

  final _i29.MercadoProducer producer;

  @override
  String toString() {
    return 'ProducerStoreRouteArgs{key: $key, producer: $producer}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ProducerStoreRouteArgs) return false;
    return key == other.key && producer == other.producer;
  }

  @override
  int get hashCode => key.hashCode ^ producer.hashCode;
}

/// generated route for
/// [_i18.ProfileRoutePage]
class ProfileRoute extends _i24.PageRouteInfo<void> {
  const ProfileRoute({List<_i24.PageRouteInfo>? children})
      : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i18.ProfileRoutePage();
    },
  );
}

/// generated route for
/// [_i19.RecoveryPasswordRoutePage]
class RecoveryPasswordRoute
    extends _i24.PageRouteInfo<RecoveryPasswordRouteArgs> {
  RecoveryPasswordRoute({
    _i25.Key? key,
    String? initialEmmail,
    List<_i24.PageRouteInfo>? children,
  }) : super(
          RecoveryPasswordRoute.name,
          args: RecoveryPasswordRouteArgs(
            key: key,
            initialEmmail: initialEmmail,
          ),
          initialChildren: children,
        );

  static const String name = 'RecoveryPasswordRoute';

  static _i24.PageInfo page = _i24.PageInfo(
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

  final _i25.Key? key;

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
/// [_i20.ScheduleRoute]
class ScheduleRoute extends _i24.PageRouteInfo<void> {
  const ScheduleRoute({List<_i24.PageRouteInfo>? children})
      : super(ScheduleRoute.name, initialChildren: children);

  static const String name = 'ScheduleRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i20.ScheduleRoute();
    },
  );
}

/// generated route for
/// [_i21.TenantHomeRoutePage]
class TenantHomeRoute extends _i24.PageRouteInfo<void> {
  const TenantHomeRoute({List<_i24.PageRouteInfo>? children})
      : super(TenantHomeRoute.name, initialChildren: children);

  static const String name = 'TenantHomeRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i21.TenantHomeRoutePage();
    },
  );
}

/// generated route for
/// [_i22.TenantMenuRoutePage]
class TenantMenuRoute extends _i24.PageRouteInfo<void> {
  const TenantMenuRoute({List<_i24.PageRouteInfo>? children})
      : super(TenantMenuRoute.name, initialChildren: children);

  static const String name = 'TenantMenuRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i22.TenantMenuRoutePage();
    },
  );
}

/// generated route for
/// [_i23.TenantTabsRoutePage]
class TenantTabsRoute extends _i24.PageRouteInfo<void> {
  const TenantTabsRoute({List<_i24.PageRouteInfo>? children})
      : super(TenantTabsRoute.name, initialChildren: children);

  static const String name = 'TenantTabsRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i23.TenantTabsRoutePage();
    },
  );
}
