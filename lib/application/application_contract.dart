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
import 'package:intl/date_symbol_data_local.dart';

abstract class ApplicationContract extends StatelessWidget {
  final _appRouter = AppRouter();

  ApplicationContract({super.key});

  final navigatorKey = GlobalKey<NavigatorState>();

  BackendContract initBackendRepository();
  AuthRepositoryContract initAuthRepository();
  Future<void> initialSettingsPlatform();

  Future<void> init() async {
    await initialSettings();
    await _initInjections();
    await initialSettingsPlatform();
  }

  @protected
  Future<void> initialSettings() async {
    WidgetsFlutterBinding.ensureInitialized();
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
    const primarySeed = Color(0xFF4FA0E3);
    const secondarySeed = Color(0xFFE80D5D);

    final primaryScheme = ColorScheme.fromSeed(
      seedColor: primarySeed,
    );
    final secondaryScheme = ColorScheme.fromSeed(
      seedColor: secondarySeed,
      brightness: primaryScheme.brightness,
    );

    final colorScheme = primaryScheme.copyWith(
      primary: primarySeed,
      onPrimary: primaryScheme.onPrimary,
      primaryContainer: primaryScheme.primaryContainer,
      onPrimaryContainer: primaryScheme.onPrimaryContainer,
      secondary: secondaryScheme.primary,
      onSecondary: secondaryScheme.onPrimary,
      secondaryContainer: secondaryScheme.primaryContainer,
      onSecondaryContainer: secondaryScheme.onPrimaryContainer,
      tertiary: secondaryScheme.secondary,
      onTertiary: secondaryScheme.onSecondary,
      tertiaryContainer: secondaryScheme.secondaryContainer,
      onTertiaryContainer: secondaryScheme.onSecondaryContainer,
    );

    return ThemeData(
      colorScheme: colorScheme,
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        selectedLabelStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        selectedIconTheme: IconThemeData(
          color: colorScheme.primary,
          size: 28,
        ),
        unselectedIconTheme: IconThemeData(
          color: colorScheme.onSurfaceVariant,
          size: 24,
        ),
        type: BottomNavigationBarType.fixed,
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
