import 'package:belluga_now/application/configurations/custom_scroll_behavior.dart';
import 'package:belluga_now/application/router/app_router.dart';
import 'package:belluga_now/application/router/modular_app/module_settings.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl_standalone.dart';
import 'package:stream_value/core/stream_value_builder.dart';

abstract class ApplicationContract extends ModularAppContract {
  ApplicationContract({super.key}) : _appRouter = AppRouter();

  final AppRouter _appRouter;
  final _moduleSettings = ModuleSettings();

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

  ThemeData getThemeData() =>
      GetIt.I.get<AppDataRepository>().appData.themeDataSettings.themeData();

  ThemeData getLightThemeData() => GetIt.I
      .get<AppDataRepository>()
      .appData
      .themeDataSettings
      .themeData(Brightness.light);

  ThemeData getDarkThemeData() => GetIt.I
      .get<AppDataRepository>()
      .appData
      .themeDataSettings
      .themeData(Brightness.dark);

  ThemeMode get themeMode => GetIt.I.get<AppDataRepository>().themeMode;

  @override
  State<ApplicationContract> createState() => _ApplicationContractState();
}

class _ApplicationContractState extends State<ApplicationContract> {
  @override
  Widget build(BuildContext context) {
    final appDataRepository = GetIt.I.get<AppDataRepository>();
    return StreamValueBuilder<ThemeMode?>(
      streamValue: appDataRepository.themeModeStreamValue,
      builder: (context, themeMode) {
        final resolvedThemeMode = themeMode ?? ThemeMode.system;
        return MaterialApp.router(
          themeMode: resolvedThemeMode,
          theme: widget.getLightThemeData(),
          darkTheme: widget.getDarkThemeData(),
          scrollBehavior: CustomScrollBehavior(),
          routerConfig: widget.appRouter.config(),
        );
      },
    );
  }
}
