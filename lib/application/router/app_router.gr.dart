// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i9;
import 'package:flutter/material.dart' as _i10;
import 'package:flutter_laravel_backend_boilerplate/presentation/init/init_screen.dart'
    as _i5;
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/auth/create_new_password/auth_create_new_password.dart'
    as _i1;
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/auth/login/auth_login_screen.dart'
    as _i2;
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/auth/recovery_password_bug/recovery_password_screen.dart'
    as _i8;
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/dashboard/dashboard_screen.dart'
    as _i3;
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/home/home_screen.dart'
    as _i4;
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/my_courses/lesson_screen.dart'
    as _i6;
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/profile/profile_screen.dart'
    as _i7;
import 'package:value_objects/domain/value_objects/mongo_id_value.dart' as _i11;

/// generated route for
/// [_i1.AuthCreateNewPasswordScreen]
class AuthCreateNewPasswordRoute extends _i9.PageRouteInfo<void> {
  const AuthCreateNewPasswordRoute({List<_i9.PageRouteInfo>? children})
    : super(AuthCreateNewPasswordRoute.name, initialChildren: children);

  static const String name = 'AuthCreateNewPasswordRoute';

  static _i9.PageInfo page = _i9.PageInfo(
    name,
    builder: (data) {
      return const _i1.AuthCreateNewPasswordScreen();
    },
  );
}

/// generated route for
/// [_i2.AuthLoginScreen]
class AuthLoginRoute extends _i9.PageRouteInfo<void> {
  const AuthLoginRoute({List<_i9.PageRouteInfo>? children})
    : super(AuthLoginRoute.name, initialChildren: children);

  static const String name = 'AuthLoginRoute';

  static _i9.PageInfo page = _i9.PageInfo(
    name,
    builder: (data) {
      return const _i2.AuthLoginScreen();
    },
  );
}

/// generated route for
/// [_i3.DashboardScreen]
class DashboardRoute extends _i9.PageRouteInfo<void> {
  const DashboardRoute({List<_i9.PageRouteInfo>? children})
    : super(DashboardRoute.name, initialChildren: children);

  static const String name = 'DashboardRoute';

  static _i9.PageInfo page = _i9.PageInfo(
    name,
    builder: (data) {
      return const _i3.DashboardScreen();
    },
  );
}

/// generated route for
/// [_i4.HomeScreen]
class HomeRoute extends _i9.PageRouteInfo<void> {
  const HomeRoute({List<_i9.PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static _i9.PageInfo page = _i9.PageInfo(
    name,
    builder: (data) {
      return const _i4.HomeScreen();
    },
  );
}

/// generated route for
/// [_i5.InitScreen]
class InitRoute extends _i9.PageRouteInfo<void> {
  const InitRoute({List<_i9.PageRouteInfo>? children})
    : super(InitRoute.name, initialChildren: children);

  static const String name = 'InitRoute';

  static _i9.PageInfo page = _i9.PageInfo(
    name,
    builder: (data) {
      return const _i5.InitScreen();
    },
  );
}

/// generated route for
/// [_i6.LessonScreen]
class LessonRoute extends _i9.PageRouteInfo<LessonRouteArgs> {
  LessonRoute({
    _i10.Key? key,
    required _i11.MongoIDValue lessonId,
    List<_i9.PageRouteInfo>? children,
  }) : super(
         LessonRoute.name,
         args: LessonRouteArgs(key: key, lessonId: lessonId),
         initialChildren: children,
       );

  static const String name = 'LessonRoute';

  static _i9.PageInfo page = _i9.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<LessonRouteArgs>();
      return _i6.LessonScreen(key: args.key, lessonId: args.lessonId);
    },
  );
}

class LessonRouteArgs {
  const LessonRouteArgs({this.key, required this.lessonId});

  final _i10.Key? key;

  final _i11.MongoIDValue lessonId;

  @override
  String toString() {
    return 'LessonRouteArgs{key: $key, lessonId: $lessonId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LessonRouteArgs) return false;
    return key == other.key && lessonId == other.lessonId;
  }

  @override
  int get hashCode => key.hashCode ^ lessonId.hashCode;
}

/// generated route for
/// [_i7.ProfileScreen]
class ProfileRoute extends _i9.PageRouteInfo<void> {
  const ProfileRoute({List<_i9.PageRouteInfo>? children})
    : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static _i9.PageInfo page = _i9.PageInfo(
    name,
    builder: (data) {
      return const _i7.ProfileScreen();
    },
  );
}

/// generated route for
/// [_i8.RecoveryPasswordScreen]
class RecoveryPasswordRoute
    extends _i9.PageRouteInfo<RecoveryPasswordRouteArgs> {
  RecoveryPasswordRoute({
    _i10.Key? key,
    String? initialEmmail,
    List<_i9.PageRouteInfo>? children,
  }) : super(
         RecoveryPasswordRoute.name,
         args: RecoveryPasswordRouteArgs(
           key: key,
           initialEmmail: initialEmmail,
         ),
         initialChildren: children,
       );

  static const String name = 'RecoveryPasswordRoute';

  static _i9.PageInfo page = _i9.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RecoveryPasswordRouteArgs>(
        orElse: () => const RecoveryPasswordRouteArgs(),
      );
      return _i8.RecoveryPasswordScreen(
        key: args.key,
        initialEmmail: args.initialEmmail,
      );
    },
  );
}

class RecoveryPasswordRouteArgs {
  const RecoveryPasswordRouteArgs({this.key, this.initialEmmail});

  final _i10.Key? key;

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
