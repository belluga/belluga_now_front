import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

abstract base class BellugaInitScreenControllerContract implements Disposable {
  AuthRepositoryContract get _authRepository;

  StreamValue<String> get loadingStatusStreamValue;

  PageRouteInfo get initialRoute => _getInitialRoute();

  Future<void> initialize() async {
    await _initilizeAuth();
  }

  Future<void> _initilizeAuth() async {
    await _authRepository.init();
  }

  PageRouteInfo _getInitialRoute();

  @override
  FutureOr onDispose() async {}
}
