import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/application/belluga_app/belluga_app.dart';
import 'package:flutter_laravel_backend_boilerplate/application/belluga_app/belluga_app_contract.dart';
import 'package:flutter_laravel_backend_boilerplate/application/configurations/belluga_constants.dart';
import 'package:flutter_laravel_backend_boilerplate/application/helpers/url_strategy/url_strategy.dart';
import 'package:flutter_laravel_backend_boilerplate/application/router/app_router.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/repositories/auth_repository_contract.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/tenant/tenant.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/repositories/auth_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class Application extends StatelessWidget {
  final _appRouter = AppRouter();
  // MainInjectorContract get mainInjector => MainInjectorGetIt.getInstance();

  Application({super.key});

  Future<void> init() async {
    setupUrlStrategy();

    await dotenv.load(fileName: ".env");

    await _initInjections();
    // await _initSingletons();

    
  }

  Future<void> _initInjections() async {
    GetIt.I.registerLazySingleton<AuthRepositoryContract>(
      () => AuthRepository(),
    );

    GetIt.I.registerLazySingleton<BellugaAppContract>(
      () => BellugaApp(),
    );

  
    final packageInfo = await PackageInfo.fromPlatform();

    GetIt.I.registerSingleton(Tenant(
      port: packageInfo.version,
      hostname: packageInfo.packageName,
      href: packageInfo.appName,
      device: BellugaConstants.settings.platform
    ));
  }

  Future<void> _initSingletons() async {
    final _authRepository = GetIt.I.get<AuthRepositoryContract>();
    final _bellugaApp = GetIt.I.get<BellugaAppContract>();

    await _authRepository.init();
    await _bellugaApp.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _appRouter.config(),
    );
  }
}
