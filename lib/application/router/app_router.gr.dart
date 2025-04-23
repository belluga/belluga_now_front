// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i6;
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/auth/login/auth_login_screen.dart'
    as _i1;
import 'package:flutter_laravel_backend_boilerplate/presentation/init/init_screen.dart'
    as _i3;
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/home/home_screen.dart'
    as _i2;
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/profile/profile_screen.dart'
    as _i4;
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/protected/protected_screen.dart'
    as _i5;

/// generated route for
/// [_i1.AuthLoginScreen]
class AuthLoginRoute extends _i6.PageRouteInfo<void> {
  const AuthLoginRoute({List<_i6.PageRouteInfo>? children})
    : super(AuthLoginRoute.name, initialChildren: children);

  static const String name = 'AuthLoginRoute';

  static _i6.PageInfo page = _i6.PageInfo(
    name,
    builder: (data) {
      return const _i1.AuthLoginScreen();
    },
  );
}

/// generated route for
/// [_i2.HomeScreen]
class HomeRoute extends _i6.PageRouteInfo<void> {
  const HomeRoute({List<_i6.PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static _i6.PageInfo page = _i6.PageInfo(
    name,
    builder: (data) {
      return const _i2.HomeScreen();
    },
  );
}

/// generated route for
/// [_i3.InitScreen]
class InitRoute extends _i6.PageRouteInfo<void> {
  const InitRoute({List<_i6.PageRouteInfo>? children})
    : super(InitRoute.name, initialChildren: children);

  static const String name = 'InitRoute';

  static _i6.PageInfo page = _i6.PageInfo(
    name,
    builder: (data) {
      return const _i3.InitScreen();
    },
  );
}

/// generated route for
/// [_i4.ProfileScreen]
class ProfileRoute extends _i6.PageRouteInfo<void> {
  const ProfileRoute({List<_i6.PageRouteInfo>? children})
    : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static _i6.PageInfo page = _i6.PageInfo(
    name,
    builder: (data) {
      return const _i4.ProfileScreen();
    },
  );
}

/// generated route for
/// [_i5.ProtectedScreen]
class ProtectedRoute extends _i6.PageRouteInfo<void> {
  const ProtectedRoute({List<_i6.PageRouteInfo>? children})
    : super(ProtectedRoute.name, initialChildren: children);

  static const String name = 'ProtectedRoute';

  static _i6.PageInfo page = _i6.PageInfo(
    name,
    builder: (data) {
      return const _i5.ProtectedScreen();
    },
  );
}
