import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_laravel_backend_boilerplate/application/helpers/url_strategy/url_strategy.dart';
import 'package:flutter_laravel_backend_boilerplate/application/router/app_router.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/controllers/remember_password_contract.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/repositories/auth_repository_contract.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/repositories/external_courses_repository_contract.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/repositories/courses_repository_contract.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/tenant/tenant.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/repositories/auth_repository.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/repositories/courses_repository.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/repositories/external_courses_repository.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/laravel_backend/backend_contract.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/laravel_backend/mock_backend.dart';
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
    GetIt.I.registerSingleton<BackendContract>(MockBackend());

    GetIt.I.registerLazySingleton<AuthRepositoryContract>(
      () => AuthRepository(),
    );

    GetIt.I.registerLazySingleton<ExternalCoursesRepositoryContract>(
      () => ExternalCoursesRepository(),
    );

    GetIt.I.registerLazySingleton<CoursesRepositoryContract>(
      () => CoursesRepository(),
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

  ThemeData _themeData() {
    return ThemeData(
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: Color(0xFF00E6B8),
        strokeWidth: 4,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF004B7C),
          foregroundColor: Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100.0),
          ),
          padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.0),
          borderSide: BorderSide(color: Color(0xFFFFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.0),
          borderSide: BorderSide(color: Color(0xFF00E6B8)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.0),
          borderSide: BorderSide(color: Color(0xFFFF0000)),
        ),
        labelStyle: TextStyle(color: Color(0xFFFFFFFF)),
      ),
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFF007FF9),
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: Color(0xFF004B7C),
        onPrimaryContainer: Color(0xFFFFFFFF),
        secondary: Color(0xFF00E6B8),
        onSecondary: Color(0xFF000000),
        secondaryContainer: Color(0xFF004B7C),
        onSecondaryContainer: Color(0xFFFFFFFF),
        error: Color(0xFFFF0000),
        onError: Color(0xFFFFFFFF),
        errorContainer: Color(0xFFB00020),
        onErrorContainer: Color(0xFFFFFFFF),
        tertiary: Color(0xFFEADDFF),
        onTertiary: Color(0xFF000000),
        tertiaryContainer: Color(0xFF3700B3),
        onTertiaryContainer: Color(0xFFFFFFFF),
        surface: Color(0xFF2E405C),
        surfaceDim: Color(0xFF1C2530),
        onSurface: Color(0xFFFFFFFF),
        onSurfaceVariant: Color(0xFFB0BEC5),
        outline: Color(0xFFB0BEC5),
        outlineVariant: Color(0xFF37474F),
        inverseSurface: Color(0xFF37474F),
        inversePrimary: Color(0xFF004B7C),
        scrim: Color(0xFF000000),
        shadow: Color(0xFF000000),
      ),
    );
  }

  // Future<void> initializeFirebase() async {
  //   await Firebase.initializeApp();
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: _themeData(),
      routerConfig: _appRouter.config(),
    );
  }
}
