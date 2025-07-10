// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i10;
import 'package:flutter/material.dart' as _i11;
import 'package:unifast_portal/presentation/init/init_screen.dart' as _i7;
import 'package:unifast_portal/presentation/screens/auth/create_new_password/auth_create_new_password.dart'
    as _i1;
import 'package:unifast_portal/presentation/screens/auth/login/auth_login_screen.dart'
    as _i2;
import 'package:unifast_portal/presentation/screens/auth/recovery_password_bug/recovery_password_screen.dart'
    as _i9;
import 'package:unifast_portal/presentation/screens/dashboard/dashboard_screen.dart'
    as _i5;
import 'package:unifast_portal/presentation/screens/home/home_screen.dart'
    as _i6;
import 'package:unifast_portal/presentation/screens/lms/course_screen.dart'
    as _i3;
import 'package:unifast_portal/presentation/screens/lms/courses_list_screen.dart'
    as _i4;
import 'package:unifast_portal/presentation/screens/profile/profile_screen.dart'
    as _i8;

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
/// [_i3.CourseScreen]
class CourseRoute extends _i10.PageRouteInfo<CourseRouteArgs> {
  CourseRoute({
    _i11.Key? key,
    required String courseItemId,
    List<_i10.PageRouteInfo>? children,
  }) : super(
         CourseRoute.name,
         args: CourseRouteArgs(key: key, courseItemId: courseItemId),
         rawPathParams: {'courseItemId': courseItemId},
         initialChildren: children,
       );

  static const String name = 'CourseRoute';

  static _i10.PageInfo page = _i10.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<CourseRouteArgs>(
        orElse: () =>
            CourseRouteArgs(courseItemId: pathParams.getString('courseItemId')),
      );
      return _i3.CourseScreen(key: args.key, courseItemId: args.courseItemId);
    },
  );
}

class CourseRouteArgs {
  const CourseRouteArgs({this.key, required this.courseItemId});

  final _i11.Key? key;

  final String courseItemId;

  @override
  String toString() {
    return 'CourseRouteArgs{key: $key, courseItemId: $courseItemId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CourseRouteArgs) return false;
    return key == other.key && courseItemId == other.courseItemId;
  }

  @override
  int get hashCode => key.hashCode ^ courseItemId.hashCode;
}

/// generated route for
/// [_i4.CoursesListScreen]
class CoursesListRoute extends _i10.PageRouteInfo<void> {
  const CoursesListRoute({List<_i10.PageRouteInfo>? children})
    : super(CoursesListRoute.name, initialChildren: children);

  static const String name = 'CoursesListRoute';

  static _i10.PageInfo page = _i10.PageInfo(
    name,
    builder: (data) {
      return const _i4.CoursesListScreen();
    },
  );
}

/// generated route for
/// [_i5.DashboardScreen]
class DashboardRoute extends _i10.PageRouteInfo<void> {
  const DashboardRoute({List<_i10.PageRouteInfo>? children})
    : super(DashboardRoute.name, initialChildren: children);

  static const String name = 'DashboardRoute';

  static _i10.PageInfo page = _i10.PageInfo(
    name,
    builder: (data) {
      return const _i5.DashboardScreen();
    },
  );
}

/// generated route for
/// [_i6.HomeScreen]
class HomeRoute extends _i10.PageRouteInfo<void> {
  const HomeRoute({List<_i10.PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static _i10.PageInfo page = _i10.PageInfo(
    name,
    builder: (data) {
      return const _i6.HomeScreen();
    },
  );
}

/// generated route for
/// [_i7.InitScreen]
class InitRoute extends _i10.PageRouteInfo<void> {
  const InitRoute({List<_i10.PageRouteInfo>? children})
    : super(InitRoute.name, initialChildren: children);

  static const String name = 'InitRoute';

  static _i10.PageInfo page = _i10.PageInfo(
    name,
    builder: (data) {
      return const _i7.InitScreen();
    },
  );
}

/// generated route for
/// [_i8.ProfileScreen]
class ProfileRoute extends _i10.PageRouteInfo<void> {
  const ProfileRoute({List<_i10.PageRouteInfo>? children})
    : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static _i10.PageInfo page = _i10.PageInfo(
    name,
    builder: (data) {
      return const _i8.ProfileScreen();
    },
  );
}

/// generated route for
/// [_i9.RecoveryPasswordScreen]
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
      return _i9.RecoveryPasswordScreen(
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
