// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i10;
import 'package:belluga_now/presentation/init/init_screen.dart' as _i4;
import 'package:belluga_now/presentation/landlord/screens/home/landlord_home_screen.dart'
    as _i5;
import 'package:belluga_now/presentation/screens/auth/create_new_password/auth_create_new_password.dart'
    as _i1;
import 'package:belluga_now/presentation/screens/auth/login/auth_login_screen.dart'
    as _i2;
import 'package:belluga_now/presentation/screens/auth/recovery_password_bug/recovery_password_screen.dart'
    as _i7;
import 'package:belluga_now/presentation/tenant/screens/home/tenant_home_screen.dart'
    as _i9;
import 'package:belluga_now/presentation/tenant/screens/profile/profile_screen.dart'
    as _i6;
import 'package:belluga_now/presentation/tenant/screens/schedule/event_search_route.dart'
    as _i3;
import 'package:belluga_now/presentation/tenant/screens/schedule/schedule_route.dart'
    as _i8;
import 'package:flutter/material.dart' as _i11;

/// generated route for
/// [_i1.AuthCreateNewPasswordScreen]
class AuthCreateNewPasswordRoute extends _i10.PageRouteInfo<void> {
  const AuthCreateNewPasswordRoute({List<_i10.PageRouteInfo>? children})
      : super(AuthCreateNewPasswordRoute.name, initialChildren: children);

  static const String name = 'AuthCreateNewPasswordRoute';

  static _i10.PageInfo page = _i10.PageInfo(
    name,
    builder: (data) {
      return const _i1.AuthCreateNewPasswordScreen();
    },
  );
}

/// generated route for
/// [_i2.AuthLoginScreen]
class AuthLoginRoute extends _i10.PageRouteInfo<void> {
  const AuthLoginRoute({List<_i10.PageRouteInfo>? children})
      : super(AuthLoginRoute.name, initialChildren: children);

  static const String name = 'AuthLoginRoute';

  static _i10.PageInfo page = _i10.PageInfo(
    name,
    builder: (data) {
      return const _i2.AuthLoginScreen();
    },
  );
}

/// generated route for
/// [_i3.EventSearchRoute]
class EventSearchRoute extends _i10.PageRouteInfo<void> {
  const EventSearchRoute({List<_i10.PageRouteInfo>? children})
      : super(EventSearchRoute.name, initialChildren: children);

  static const String name = 'EventSearchRoute';

  static _i10.PageInfo page = _i10.PageInfo(
    name,
    builder: (data) {
      return const _i3.EventSearchRoute();
    },
  );
}

/// generated route for
/// [_i4.InitScreen]
class InitRoute extends _i10.PageRouteInfo<void> {
  const InitRoute({List<_i10.PageRouteInfo>? children})
      : super(InitRoute.name, initialChildren: children);

  static const String name = 'InitRoute';

  static _i10.PageInfo page = _i10.PageInfo(
    name,
    builder: (data) {
      return const _i4.InitScreen();
    },
  );
}

/// generated route for
/// [_i5.LandlordHomeScreen]
class LandlordHomeRoute extends _i10.PageRouteInfo<void> {
  const LandlordHomeRoute({List<_i10.PageRouteInfo>? children})
      : super(LandlordHomeRoute.name, initialChildren: children);

  static const String name = 'LandlordHomeRoute';

  static _i10.PageInfo page = _i10.PageInfo(
    name,
    builder: (data) {
      return const _i5.LandlordHomeScreen();
    },
  );
}

/// generated route for
/// [_i6.ProfileScreen]
class ProfileRoute extends _i10.PageRouteInfo<void> {
  const ProfileRoute({List<_i10.PageRouteInfo>? children})
      : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static _i10.PageInfo page = _i10.PageInfo(
    name,
    builder: (data) {
      return const _i6.ProfileScreen();
    },
  );
}

/// generated route for
/// [_i7.RecoveryPasswordScreen]
class RecoveryPasswordRoute
    extends _i10.PageRouteInfo<RecoveryPasswordRouteArgs> {
  RecoveryPasswordRoute({
    _i11.Key? key,
    String? initialEmmail,
    List<_i10.PageRouteInfo>? children,
  }) : super(
          RecoveryPasswordRoute.name,
          args: RecoveryPasswordRouteArgs(
            key: key,
            initialEmmail: initialEmmail,
          ),
          initialChildren: children,
        );

  static const String name = 'RecoveryPasswordRoute';

  static _i10.PageInfo page = _i10.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RecoveryPasswordRouteArgs>(
        orElse: () => const RecoveryPasswordRouteArgs(),
      );
      return _i7.RecoveryPasswordScreen(
        key: args.key,
        initialEmmail: args.initialEmmail,
      );
    },
  );
}

class RecoveryPasswordRouteArgs {
  const RecoveryPasswordRouteArgs({this.key, this.initialEmmail});

  final _i11.Key? key;

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
/// [_i8.ScheduleRoute]
class ScheduleRoute extends _i10.PageRouteInfo<void> {
  const ScheduleRoute({List<_i10.PageRouteInfo>? children})
      : super(ScheduleRoute.name, initialChildren: children);

  static const String name = 'ScheduleRoute';

  static _i10.PageInfo page = _i10.PageInfo(
    name,
    builder: (data) {
      return const _i8.ScheduleRoute();
    },
  );
}

/// generated route for
/// [_i9.TenantHomeScreen]
class TenantHomeRoute extends _i10.PageRouteInfo<void> {
  const TenantHomeRoute({List<_i10.PageRouteInfo>? children})
      : super(TenantHomeRoute.name, initialChildren: children);

  static const String name = 'TenantHomeRoute';

  static _i10.PageInfo page = _i10.PageInfo(
    name,
    builder: (data) {
      return const _i9.TenantHomeScreen();
    },
  );
}
