import 'package:belluga_now/application/configurations/custom_scroll_behavior.dart';
import 'package:belluga_now/application/router/app_router.dart';
import 'package:belluga_now/application/router/modular_app/module_settings.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/infrastructure/services/dal/dao/backend_contract.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl_standalone.dart';

abstract class ApplicationContract extends ModularAppContract {
  ApplicationContract({super.key}) : _appRouter = AppRouter() {
    _moduleSettings = ModuleSettings(
      backendBuilder: initBackendRepository,
      authRepositoryBuilder: initAuthRepository,
    );
  }

  final AppRouter _appRouter;
  late final ModuleSettings _moduleSettings;

  BackendContract initBackendRepository();
  AuthRepositoryContract initAuthRepository();
  Future<void> initialSettingsPlatform();

  @override
  AppRouter get appRouter => _appRouter;

  @override
  ModuleSettings get moduleSettings => _moduleSettings;

  Future<void> initialSettings() async {
    WidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting();
    await findSystemLocale();
  }

  @override
  Future<void> init() async {
    await initialSettings();
    await initialSettingsPlatform();
    await super.init();
  }

  ThemeData getThemeData() {
    const primarySeed = Color(0xFF4FA0E3);
    const secondarySeed = Color(0xFFE80D5D);

    final primaryScheme = ColorScheme.fromSeed(seedColor: primarySeed);
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
  State<ApplicationContract> createState() => _ApplicationContractState();
}

class _ApplicationContractState extends State<ApplicationContract> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: widget.getThemeData(),
      scrollBehavior: CustomScrollBehavior(),
      routerConfig: widget.appRouter.config(),
    );
  }
}
