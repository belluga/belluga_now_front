// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i19;
import 'package:belluga_now/domain/experiences/experience_model.dart' as _i21;
import 'package:belluga_now/domain/invites/invite_friend_model.dart' as _i23;
import 'package:belluga_now/domain/invites/invite_model.dart' as _i22;
import 'package:belluga_now/domain/map/city_poi_model.dart' as _i25;
import 'package:belluga_now/presentation/init/init_screen.dart' as _i7;
import 'package:belluga_now/presentation/landlord/screens/home/landlord_home_route.dart'
    as _i10;
import 'package:belluga_now/presentation/screens/auth/create_new_password/auth_create_new_password_route.dart'
    as _i1;
import 'package:belluga_now/presentation/screens/auth/login/auth_login_route.dart'
    as _i2;
import 'package:belluga_now/presentation/screens/auth/recovery_password_bug/recovery_password_route.dart'
    as _i15;
import 'package:belluga_now/presentation/tenant/screens/experiences/experience_detail_route.dart'
    as _i5;
import 'package:belluga_now/presentation/tenant/screens/experiences/experiences_route.dart'
    as _i6;
import 'package:belluga_now/presentation/tenant/screens/home/tenant_home_route.dart'
    as _i17;
import 'package:belluga_now/presentation/tenant/screens/invites/invite_flow_route.dart'
    as _i8;
import 'package:belluga_now/presentation/tenant/screens/invites/invite_share_route.dart'
    as _i9;
import 'package:belluga_now/presentation/tenant/screens/map/city_map_route.dart'
    as _i3;
import 'package:belluga_now/presentation/tenant/screens/map/poi_details_route.dart'
    as _i12;
import 'package:belluga_now/presentation/tenant/screens/mercado/mercado_route.dart'
    as _i11;
import 'package:belluga_now/presentation/tenant/screens/mercado/models/mercado_producer.dart'
    as _i26;
import 'package:belluga_now/presentation/tenant/screens/mercado/producer_store_route.dart'
    as _i13;
import 'package:belluga_now/presentation/tenant/screens/profile/profile_route.dart'
    as _i14;
import 'package:belluga_now/presentation/tenant/screens/schedule/event_search_route.dart'
    as _i4;
import 'package:belluga_now/presentation/tenant/screens/schedule/schedule_route.dart'
    as _i16;
import 'package:belluga_now/presentation/tenant/screens/tabs/tenant_tabs_route.dart'
    as _i18;
import 'package:collection/collection.dart' as _i24;
import 'package:flutter/material.dart' as _i20;

/// generated route for
/// [_i1.AuthCreateNewPasswordRoutePage]
class AuthCreateNewPasswordRoute extends _i19.PageRouteInfo<void> {
  const AuthCreateNewPasswordRoute({List<_i19.PageRouteInfo>? children})
      : super(AuthCreateNewPasswordRoute.name, initialChildren: children);

  static const String name = 'AuthCreateNewPasswordRoute';

  static _i19.PageInfo page = _i19.PageInfo(
    name,
    builder: (data) {
      return const _i1.AuthCreateNewPasswordRoutePage();
    },
  );
}

/// generated route for
/// [_i2.AuthLoginRoutePage]
class AuthLoginRoute extends _i19.PageRouteInfo<void> {
  const AuthLoginRoute({List<_i19.PageRouteInfo>? children})
      : super(AuthLoginRoute.name, initialChildren: children);

  static const String name = 'AuthLoginRoute';

  static _i19.PageInfo page = _i19.PageInfo(
    name,
    builder: (data) {
      return const _i2.AuthLoginRoutePage();
    },
  );
}

/// generated route for
/// [_i3.CityMapRoutePage]
class CityMapRoute extends _i19.PageRouteInfo<void> {
  const CityMapRoute({List<_i19.PageRouteInfo>? children})
      : super(CityMapRoute.name, initialChildren: children);

  static const String name = 'CityMapRoute';

  static _i19.PageInfo page = _i19.PageInfo(
    name,
    builder: (data) {
      return const _i3.CityMapRoutePage();
    },
  );
}

/// generated route for
/// [_i4.EventSearchRoute]
class EventSearchRoute extends _i19.PageRouteInfo<void> {
  const EventSearchRoute({List<_i19.PageRouteInfo>? children})
      : super(EventSearchRoute.name, initialChildren: children);

  static const String name = 'EventSearchRoute';

  static _i19.PageInfo page = _i19.PageInfo(
    name,
    builder: (data) {
      return const _i4.EventSearchRoute();
    },
  );
}

/// generated route for
/// [_i5.ExperienceDetailRoutePage]
class ExperienceDetailRoute
    extends _i19.PageRouteInfo<ExperienceDetailRouteArgs> {
  ExperienceDetailRoute({
    _i20.Key? key,
    required _i21.ExperienceModel experience,
    List<_i19.PageRouteInfo>? children,
  }) : super(
          ExperienceDetailRoute.name,
          args: ExperienceDetailRouteArgs(key: key, experience: experience),
          initialChildren: children,
        );

  static const String name = 'ExperienceDetailRoute';

  static _i19.PageInfo page = _i19.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ExperienceDetailRouteArgs>();
      return _i5.ExperienceDetailRoutePage(
        key: args.key,
        experience: args.experience,
      );
    },
  );
}

class ExperienceDetailRouteArgs {
  const ExperienceDetailRouteArgs({this.key, required this.experience});

  final _i20.Key? key;

  final _i21.ExperienceModel experience;

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
/// [_i6.ExperiencesRoutePage]
class ExperiencesRoute extends _i19.PageRouteInfo<void> {
  const ExperiencesRoute({List<_i19.PageRouteInfo>? children})
      : super(ExperiencesRoute.name, initialChildren: children);

  static const String name = 'ExperiencesRoute';

  static _i19.PageInfo page = _i19.PageInfo(
    name,
    builder: (data) {
      return const _i6.ExperiencesRoutePage();
    },
  );
}

/// generated route for
/// [_i7.InitScreen]
class InitRoute extends _i19.PageRouteInfo<void> {
  const InitRoute({List<_i19.PageRouteInfo>? children})
      : super(InitRoute.name, initialChildren: children);

  static const String name = 'InitRoute';

  static _i19.PageInfo page = _i19.PageInfo(
    name,
    builder: (data) {
      return const _i7.InitScreen();
    },
  );
}

/// generated route for
/// [_i8.InviteFlowRoutePage]
class InviteFlowRoute extends _i19.PageRouteInfo<void> {
  const InviteFlowRoute({List<_i19.PageRouteInfo>? children})
      : super(InviteFlowRoute.name, initialChildren: children);

  static const String name = 'InviteFlowRoute';

  static _i19.PageInfo page = _i19.PageInfo(
    name,
    builder: (data) {
      return const _i8.InviteFlowRoutePage();
    },
  );
}

/// generated route for
/// [_i9.InviteShareRoutePage]
class InviteShareRoute extends _i19.PageRouteInfo<InviteShareRouteArgs> {
  InviteShareRoute({
    _i20.Key? key,
    required _i22.InviteModel invite,
    required List<_i23.InviteFriendModel> friends,
    List<_i19.PageRouteInfo>? children,
  }) : super(
          InviteShareRoute.name,
          args:
              InviteShareRouteArgs(key: key, invite: invite, friends: friends),
          initialChildren: children,
        );

  static const String name = 'InviteShareRoute';

  static _i19.PageInfo page = _i19.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<InviteShareRouteArgs>();
      return _i9.InviteShareRoutePage(
        key: args.key,
        invite: args.invite,
        friends: args.friends,
      );
    },
  );
}

class InviteShareRouteArgs {
  const InviteShareRouteArgs({
    this.key,
    required this.invite,
    required this.friends,
  });

  final _i20.Key? key;

  final _i22.InviteModel invite;

  final List<_i23.InviteFriendModel> friends;

  @override
  String toString() {
    return 'InviteShareRouteArgs{key: $key, invite: $invite, friends: $friends}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! InviteShareRouteArgs) return false;
    return key == other.key &&
        invite == other.invite &&
        const _i24.ListEquality<_i23.InviteFriendModel>().equals(
          friends,
          other.friends,
        );
  }

  @override
  int get hashCode =>
      key.hashCode ^
      invite.hashCode ^
      const _i24.ListEquality<_i23.InviteFriendModel>().hash(friends);
}

/// generated route for
/// [_i10.LandlordHomeRoutePage]
class LandlordHomeRoute extends _i19.PageRouteInfo<void> {
  const LandlordHomeRoute({List<_i19.PageRouteInfo>? children})
      : super(LandlordHomeRoute.name, initialChildren: children);

  static const String name = 'LandlordHomeRoute';

  static _i19.PageInfo page = _i19.PageInfo(
    name,
    builder: (data) {
      return const _i10.LandlordHomeRoutePage();
    },
  );
}

/// generated route for
/// [_i11.MercadoRoutePage]
class MercadoRoute extends _i19.PageRouteInfo<void> {
  const MercadoRoute({List<_i19.PageRouteInfo>? children})
      : super(MercadoRoute.name, initialChildren: children);

  static const String name = 'MercadoRoute';

  static _i19.PageInfo page = _i19.PageInfo(
    name,
    builder: (data) {
      return const _i11.MercadoRoutePage();
    },
  );
}

/// generated route for
/// [_i12.PoiDetailsRoutePage]
class PoiDetailsRoute extends _i19.PageRouteInfo<PoiDetailsRouteArgs> {
  PoiDetailsRoute({
    _i20.Key? key,
    required _i25.CityPoiModel poi,
    List<_i19.PageRouteInfo>? children,
  }) : super(
          PoiDetailsRoute.name,
          args: PoiDetailsRouteArgs(key: key, poi: poi),
          initialChildren: children,
        );

  static const String name = 'PoiDetailsRoute';

  static _i19.PageInfo page = _i19.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PoiDetailsRouteArgs>();
      return _i12.PoiDetailsRoutePage(key: args.key, poi: args.poi);
    },
  );
}

class PoiDetailsRouteArgs {
  const PoiDetailsRouteArgs({this.key, required this.poi});

  final _i20.Key? key;

  final _i25.CityPoiModel poi;

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
/// [_i13.ProducerStoreRoutePage]
class ProducerStoreRoute extends _i19.PageRouteInfo<ProducerStoreRouteArgs> {
  ProducerStoreRoute({
    _i20.Key? key,
    required _i26.MercadoProducer producer,
    List<_i19.PageRouteInfo>? children,
  }) : super(
          ProducerStoreRoute.name,
          args: ProducerStoreRouteArgs(key: key, producer: producer),
          initialChildren: children,
        );

  static const String name = 'ProducerStoreRoute';

  static _i19.PageInfo page = _i19.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ProducerStoreRouteArgs>();
      return _i13.ProducerStoreRoutePage(
        key: args.key,
        producer: args.producer,
      );
    },
  );
}

class ProducerStoreRouteArgs {
  const ProducerStoreRouteArgs({this.key, required this.producer});

  final _i20.Key? key;

  final _i26.MercadoProducer producer;

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
/// [_i14.ProfileRoutePage]
class ProfileRoute extends _i19.PageRouteInfo<void> {
  const ProfileRoute({List<_i19.PageRouteInfo>? children})
      : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static _i19.PageInfo page = _i19.PageInfo(
    name,
    builder: (data) {
      return const _i14.ProfileRoutePage();
    },
  );
}

/// generated route for
/// [_i15.RecoveryPasswordRoutePage]
class RecoveryPasswordRoute
    extends _i19.PageRouteInfo<RecoveryPasswordRouteArgs> {
  RecoveryPasswordRoute({
    _i20.Key? key,
    String? initialEmmail,
    List<_i19.PageRouteInfo>? children,
  }) : super(
          RecoveryPasswordRoute.name,
          args: RecoveryPasswordRouteArgs(
            key: key,
            initialEmmail: initialEmmail,
          ),
          initialChildren: children,
        );

  static const String name = 'RecoveryPasswordRoute';

  static _i19.PageInfo page = _i19.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RecoveryPasswordRouteArgs>(
        orElse: () => const RecoveryPasswordRouteArgs(),
      );
      return _i15.RecoveryPasswordRoutePage(
        key: args.key,
        initialEmmail: args.initialEmmail,
      );
    },
  );
}

class RecoveryPasswordRouteArgs {
  const RecoveryPasswordRouteArgs({this.key, this.initialEmmail});

  final _i20.Key? key;

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
/// [_i16.ScheduleRoute]
class ScheduleRoute extends _i19.PageRouteInfo<void> {
  const ScheduleRoute({List<_i19.PageRouteInfo>? children})
      : super(ScheduleRoute.name, initialChildren: children);

  static const String name = 'ScheduleRoute';

  static _i19.PageInfo page = _i19.PageInfo(
    name,
    builder: (data) {
      return const _i16.ScheduleRoute();
    },
  );
}

/// generated route for
/// [_i17.TenantHomeRoutePage]
class TenantHomeRoute extends _i19.PageRouteInfo<void> {
  const TenantHomeRoute({List<_i19.PageRouteInfo>? children})
      : super(TenantHomeRoute.name, initialChildren: children);

  static const String name = 'TenantHomeRoute';

  static _i19.PageInfo page = _i19.PageInfo(
    name,
    builder: (data) {
      return const _i17.TenantHomeRoutePage();
    },
  );
}

/// generated route for
/// [_i18.TenantTabsRoutePage]
class TenantTabsRoute extends _i19.PageRouteInfo<void> {
  const TenantTabsRoute({List<_i19.PageRouteInfo>? children})
      : super(TenantTabsRoute.name, initialChildren: children);

  static const String name = 'TenantTabsRoute';

  static _i19.PageInfo page = _i19.PageInfo(
    name,
    builder: (data) {
      return const _i18.TenantTabsRoutePage();
    },
  );
}
