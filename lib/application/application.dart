import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_laravel_backend_boilerplate/application/helpers/url_strategy/url_strategy.dart';
import 'package:flutter_laravel_backend_boilerplate/application/router/app_router.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/controllers/remember_password_contract.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/repositories/auth_repository_contract.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/tenant/tenant.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/repositories/auth_repository.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/auth/login/controller/remember_password_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl_standalone.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';

class Application extends StatelessWidget {
  final _appRouter = AppRouter();
  // MainInjectorContract get mainInjector => MainInjectorGetIt.getInstance();

  Application({super.key});

  final navigatorKey = GlobalKey<NavigatorState>();

  Future<void> init() async {
    await _setup();
    await _initInjections();
    await _initSingletons();
  }

  Future<void> _setup() async {
    setupUrlStrategy();

    await dotenv.load(fileName: ".env");

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    await initializeDateFormatting();
    await findSystemLocale();
  }

  Future<void> _initInjections() async {
    GetIt.I.registerLazySingleton<AuthRepositoryContract>(
      () => AuthRepository(),
    );

  GetIt.I.registerLazySingleton<RememberPasswordContract>(
    () => RememberPasswordController(),
  );    

    final tenant = Tenant();
    await tenant.initialize();
    GetIt.I.registerSingleton(tenant);

    // await initializeFirebase();
  }

  Future<void> _initSingletons() async {
    final _authRepository = GetIt.I.get<AuthRepositoryContract>();

    await _authRepository.init();
  }

  // Future<void> initializeFirebase() async {
  //   await Firebase.initializeApp();
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: _appRouter.config());
  }
}
