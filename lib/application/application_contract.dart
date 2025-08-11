import 'package:belluga_now/domain/repositories/tenant_repository_contract.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_repository.dart';
import 'package:flutter/material.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/application/configurations/custom_scroll_behavior.dart';
import 'package:belluga_now/application/router/app_router.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/infrastructure/services/dal/dao/backend_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl_standalone.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';

abstract class ApplicationContract extends StatelessWidget {
  final _appRouter = AppRouter();

  ApplicationContract({super.key});

  final navigatorKey = GlobalKey<NavigatorState>();

  BackendContract initBackendRepository();
  AuthRepositoryContract initAuthRepository();
  Future<void> initialSettingsPlatform();

  Future<void> init() async {
    debugPrint("init");
    debugPrint("initialSettings");
    await initialSettings();
    debugPrint("_initInjections");
    await _initInjections();
    debugPrint("initialSettingsPlatform");
    await initialSettingsPlatform();
  }

  @protected
  Future<void> initialSettings() async {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: ".env");
    await initializeDateFormatting();
    await findSystemLocale();
    await _initAppData();
    await _initBackend();
    await _initTenant();
  }

  Future<void> _initAppData() async {
    final appData = AppData();
    await appData.initialize();
    GetIt.I.registerSingleton<AppData>(appData);
  }

  Future<void> _initBackend() async {
    GetIt.I.registerSingleton<BackendContract>(initBackendRepository());
  }

  Future<void> _initTenant() async {
    final _tenant = TenantRepository();
    await _tenant.init();
    GetIt.I.registerSingleton<TenantRepositoryContract>(_tenant);
  }

  Future<void> _initInjections() async {
    GetIt.I.registerLazySingleton<AuthRepositoryContract>(
      () => initAuthRepository(),
    );
  }

  ThemeData getThemeData() {
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: getThemeData(),
      scrollBehavior: CustomScrollBehavior(),
      routerConfig: _appRouter.config(),
    );
  }
}
