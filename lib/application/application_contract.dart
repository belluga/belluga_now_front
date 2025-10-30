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

    final _colorScheme = ColorScheme.fromSeed(seedColor: Color(0xFF00E6B8));

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF00E6B8)),
      bottomAppBarTheme: BottomAppBarThemeData(
        color: _colorScheme.primaryContainer,
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
