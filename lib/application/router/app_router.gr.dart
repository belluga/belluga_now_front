// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i8;
import 'package:belluga_now/presentation/init/init_screen.dart' as _i3;
import 'package:belluga_now/presentation/screens/auth/create_new_password/auth_create_new_password.dart'
    as _i1;
import 'package:belluga_now/presentation/screens/auth/login/auth_login_screen.dart'
    as _i2;
import 'package:belluga_now/presentation/screens/auth/recovery_password_bug/recovery_password_screen.dart'
    as _i6;
import 'package:belluga_now/presentation/screens/home_landlord/landlord_home_screen.dart'
    as _i4;
import 'package:belluga_now/presentation/screens/home_tenant/tenant_home_screen.dart'
    as _i7;
import 'package:belluga_now/presentation/screens/profile/profile_screen.dart'
    as _i5;
import 'package:flutter/material.dart' as _i9;

/// generated route for
/// [_i1.AuthCreateNewPasswordScreen]
class AuthCreateNewPasswordRoute extends _i8.PageRouteInfo<void> {
  const AuthCreateNewPasswordRoute({List<_i8.PageRouteInfo>? children})
      : super(AuthCreateNewPasswordRoute.name, initialChildren: children);

  static const String name = 'AuthCreateNewPasswordRoute';

  static _i8.PageInfo page = _i8.PageInfo(
    name,
    builder: (data) {
      return const _i1.AuthCreateNewPasswordScreen();
    },
  );
}

/// generated route for
/// [_i2.AuthLoginScreen]
class AuthLoginRoute extends _i8.PageRouteInfo<void> {
  const AuthLoginRoute({List<_i8.PageRouteInfo>? children})
      : super(AuthLoginRoute.name, initialChildren: children);

  static const String name = 'AuthLoginRoute';

  static _i8.PageInfo page = _i8.PageInfo(
    name,
    builder: (data) {
      return const _i2.AuthLoginScreen();
    },
  );
}

/// generated route for
/// [_i3.InitScreen]
class InitRoute extends _i8.PageRouteInfo<void> {
  const InitRoute({List<_i8.PageRouteInfo>? children})
      : super(InitRoute.name, initialChildren: children);

  static const String name = 'InitRoute';

  static _i8.PageInfo page = _i8.PageInfo(
    name,
    builder: (data) {
      return const _i3.InitScreen();
    },
  );
}

/// generated route for
/// [_i4.LandlordHomeScreen]
class LandlordHomeRoute extends _i8.PageRouteInfo<void> {
  const LandlordHomeRoute({List<_i8.PageRouteInfo>? children})
      : super(LandlordHomeRoute.name, initialChildren: children);

  static const String name = 'LandlordHomeRoute';

  static _i8.PageInfo page = _i8.PageInfo(
    name,
    builder: (data) {
      return const _i4.LandlordHomeScreen();
    },
  );
}

/// generated route for
/// [_i5.ProfileScreen]
class ProfileRoute extends _i8.PageRouteInfo<void> {
  const ProfileRoute({List<_i8.PageRouteInfo>? children})
      : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static _i8.PageInfo page = _i8.PageInfo(
    name,
    builder: (data) {
      return const _i5.ProfileScreen();
    },
  );
}

/// generated route for
/// [_i6.RecoveryPasswordScreen]
class RecoveryPasswordRoute
    extends _i8.PageRouteInfo<RecoveryPasswordRouteArgs> {
  RecoveryPasswordRoute({
    _i9.Key? key,
    String? initialEmmail,
    List<_i8.PageRouteInfo>? children,
  }) : super(
          RecoveryPasswordRoute.name,
          args: RecoveryPasswordRouteArgs(
            key: key,
            initialEmmail: initialEmmail,
          ),
          initialChildren: children,
        );

  static const String name = 'RecoveryPasswordRoute';

  static _i8.PageInfo page = _i8.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RecoveryPasswordRouteArgs>(
        orElse: () => const RecoveryPasswordRouteArgs(),
      );
      return _i6.RecoveryPasswordScreen(
        key: args.key,
        initialEmmail: args.initialEmmail,
      );
    },
  );
}

class RecoveryPasswordRouteArgs {
  const RecoveryPasswordRouteArgs({this.key, this.initialEmmail});

  final _i9.Key? key;

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
/// [_i7.TenantHomeScreen]
class TenantHomeRoute extends _i8.PageRouteInfo<void> {
  const TenantHomeRoute({List<_i8.PageRouteInfo>? children})
      : super(TenantHomeRoute.name, initialChildren: children);

  static const String name = 'TenantHomeRoute';

  static _i8.PageInfo page = _i8.PageInfo(
    name,
    builder: (data) {
      return const _i7.TenantHomeScreen();
    },
  );
}
