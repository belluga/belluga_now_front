import 'package:belluga_now/application/application.dart';
import 'package:belluga_now/application/application_contract.dart';
import 'package:belluga_now/domain/app_data/platform_type.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/local/app_data_local_info_source/app_data_local_info_source_stub.dart';
import 'package:belluga_now/infrastructure/dal/dto/app_data_dto.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:belluga_now/presentation/prototypes/map_experience/map_experience_prototype_screen.dart';
import 'package:belluga_now/presentation/tenant/schedule/widgets/agenda_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> _waitForFinder(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 30),
    Duration step = const Duration(milliseconds: 300),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(step);
      if (finder.evaluate().isNotEmpty) {
        return;
      }
    }
    throw TestFailure('Timed out waiting for ${finder.description}.');
  }

  Future<void> _dismissInviteOverlayIfNeeded(WidgetTester tester) async {
    final closeButton = find.byTooltip('Fechar');
    if (closeButton.evaluate().isNotEmpty) {
      await tester.tap(closeButton.first);
      await tester.pumpAndSettle();
    }
  }

  Future<void> _dismissLocationGateIfNeeded(WidgetTester tester) async {
    final allowButton = find.text('Permitir localização');
    if (allowButton.evaluate().isNotEmpty) {
      await tester.tap(allowButton.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    final continueButton = find.text('Continuar sem localização ao vivo');
    if (continueButton.evaluate().isNotEmpty) {
      await tester.tap(continueButton.first);
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }

    final notNowButton = find.text('Agora não');
    if (notNowButton.evaluate().isNotEmpty) {
      await tester.tap(notNowButton.first);
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }
  }

  testWidgets(
    'Home to Map to Home to Menu to Agenda navigation',
    (tester) async {
      if (GetIt.I.isRegistered<ApplicationContract>()) {
        GetIt.I.unregister<ApplicationContract>();
      }
      if (GetIt.I.isRegistered<AppDataRepository>()) {
        GetIt.I.unregister<AppDataRepository>();
      }
      GetIt.I.registerSingleton<AppDataRepository>(
        AppDataRepository(
          backend: FakeAppDataBackend(),
          localInfoSource: FakeAppDataLocalInfoSource(),
        ),
      );
      final app = Application();
      GetIt.I.registerSingleton<ApplicationContract>(app);
      await app.init();

      await tester.pumpWidget(app);

      await tester.pumpAndSettle(const Duration(seconds: 2));
      await _dismissLocationGateIfNeeded(tester);
      await _dismissInviteOverlayIfNeeded(tester);
      await _waitForFinder(tester, find.text('Seus Favoritos'));

      await tester.tap(find.widgetWithText(NavigationDestination, 'Mapa'));
      await tester.pumpAndSettle();
      await _dismissLocationGateIfNeeded(tester);
      await _waitForFinder(tester, find.byType(MapExperiencePrototypeScreen));

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await _dismissLocationGateIfNeeded(tester);
      await _dismissInviteOverlayIfNeeded(tester);
      await _waitForFinder(tester, find.text('Seus Favoritos'));

      await tester.tap(find.widgetWithText(NavigationDestination, 'Menu'));
      await tester.pumpAndSettle();
      await _waitForFinder(tester, find.text('Seu Perfil'));

      await tester.tap(find.text('Meus eventos confirmados'));
      await tester.pumpAndSettle();
      expect(find.byType(AgendaAppBar), findsOneWidget);
      expect(find.text('Agenda'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('Seus Favoritos'), findsOneWidget);
    },
  );
}

class FakeAppDataBackend implements AppDataBackendContract {
  @override
  Future<AppDataDTO> fetch() async {
    return AppDataDTO(
      name: 'Test',
      type: 'tenant',
      mainDomain: 'example.com',
      themeDataSettings: const {
        'primary_seed_color': '#4FA0E3',
        'secondary_seed_color': '#E80D5D',
        'brightness_default': 'light',
      },
    );
  }
}

class FakeAppDataLocalInfoSource extends AppDataLocalInfoSource {
  @override
  Future<Map<String, dynamic>> getInfo() async {
    final platformTypeValue = PlatformTypeValue(
      defaultValue: PlatformType.mobile,
    )..parse(PlatformType.mobile.name);
    return {
      'platformType': platformTypeValue,
      'port': '0.0.0',
      'hostname': 'example.com',
      'href': 'https://example.com',
      'device': 'test_device',
    };
  }
}
