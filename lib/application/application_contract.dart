import 'package:belluga_now/application/configurations/custom_scroll_behavior.dart';
import 'package:belluga_now/application/router/app_router.dart';
import 'package:belluga_now/application/router/modular_app/module_settings.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/infrastructure/services/dal/dao/backend_contract.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:get_it/get_it.dart';
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
  AppDataRepository initAppDataRepository();
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

    final appDataRepository = initAppDataRepository();
    await appDataRepository.init();
    GetIt.I.registerSingleton<AppDataRepository>(appDataRepository);

    await super.init();
  }

  ThemeData getThemeData() {
    final appData = GetIt.I.get<AppDataRepository>().appData;
    // For now using light theme by default, or we could check platform brightness
    return appData.themeDataSettings.themeData(Brightness.light);
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
