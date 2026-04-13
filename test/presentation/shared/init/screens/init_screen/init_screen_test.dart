import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/presentation/shared/init/screens/init_screen/controllers/init_screen_controller.dart';
import 'package:belluga_now/presentation/shared/init/screens/init_screen/init_screen.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/testing/domain_factories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets('uses light main logo on the init screen in light mode',
      (tester) async {
    final appData = _buildAppData(brightnessDefault: 'light');
    GetIt.I.registerSingleton<InitScreenController>(
      InitScreenController(
        appDataRepository: _FakeAppDataRepository(appData, ThemeMode.light),
        invitesRepository: _FakeInvitesRepository(),
      ),
    );

    await tester.pumpWidget(_buildTestApp(appData, ThemeMode.light));
    await tester.pump();

    final logo = tester.widget<BellugaNetworkImage>(
      find.byType(BellugaNetworkImage),
    );
    expect(logo.url, 'https://guarappari.test/logo-light.png');
  });

  testWidgets('uses dark main logo on the init screen in dark mode',
      (tester) async {
    final appData = _buildAppData(brightnessDefault: 'dark');
    GetIt.I.registerSingleton<InitScreenController>(
      InitScreenController(
        appDataRepository: _FakeAppDataRepository(appData, ThemeMode.dark),
        invitesRepository: _FakeInvitesRepository(),
      ),
    );

    await tester.pumpWidget(_buildTestApp(appData, ThemeMode.dark));
    await tester.pump();

    final logo = tester.widget<BellugaNetworkImage>(
      find.byType(BellugaNetworkImage),
    );
    expect(logo.url, 'https://guarappari.test/logo-dark.png');
  });
}

Widget _buildTestApp(AppData appData, ThemeMode themeMode) {
  return MaterialApp(
    theme: appData.themeDataSettings.themeDataLight(),
    darkTheme: appData.themeDataSettings.themeDataDark(),
    themeMode: themeMode,
    home: const InitScreen(),
  );
}

AppData _buildAppData({required String brightnessDefault}) {
  return buildAppDataFromInitialization(
    remoteData: <String, dynamic>{
      'tenant_id': 'tenant-1',
      'name': 'Guarappari',
      'type': 'tenant',
      'main_domain': 'https://guarappari.test',
      'domains': const <String>['https://guarappari.test'],
      'app_domains': const <String>[],
      'theme_data_settings': <String, dynamic>{
        'brightness_default': brightnessDefault,
        'primary_seed_color': '#4FA0E3',
        'secondary_seed_color': '#17324D',
      },
      'main_logo_light_url': 'https://guarappari.test/logo-light.png',
      'main_logo_dark_url': 'https://guarappari.test/logo-dark.png',
      'main_icon_light_url': 'https://guarappari.test/icon-light.png',
      'main_icon_dark_url': 'https://guarappari.test/icon-dark.png',
    },
    localInfo: <String, dynamic>{
      'hostname': 'guarappari.test',
      'href': 'https://guarappari.test/',
      'device': 'browser',
    },
  );
}

class _FakeAppDataRepository extends AppDataRepositoryContract {
  _FakeAppDataRepository(this.appData, ThemeMode themeMode)
      : _themeMode = themeMode,
        _themeModeStreamValue = StreamValue<ThemeMode?>(
          defaultValue: themeMode,
        );

  @override
  final AppData appData;

  final ThemeMode _themeMode;
  final StreamValue<ThemeMode?> _themeModeStreamValue;

  @override
  ThemeMode get themeMode => _themeMode;

  @override
  StreamValue<ThemeMode?> get themeModeStreamValue => _themeModeStreamValue;

  @override
  StreamValue<DistanceInMetersValue> get maxRadiusMetersStreamValue =>
      StreamValue<DistanceInMetersValue>(
        defaultValue: DistanceInMetersValue.fromRaw(
          1000,
          defaultValue: 1000,
        ),
      );

  @override
  DistanceInMetersValue get maxRadiusMeters =>
      DistanceInMetersValue.fromRaw(1000, defaultValue: 1000);

  @override
  Future<void> init() async {}

  @override
  Future<void> setMaxRadiusMeters(DistanceInMetersValue meters) async {}

  @override
  Future<void> setThemeMode(AppThemeModeValue mode) async {}
}

class _FakeInvitesRepository extends InvitesRepositoryContract {
  @override
  Future<List<InviteModel>> fetchInvites({
    InvitesRepositoryContractPrimInt? page,
    InvitesRepositoryContractPrimInt? pageSize,
  }) async {
    return const <InviteModel>[];
  }

  @override
  Future<InviteRuntimeSettings> fetchSettings() async =>
      buildInviteRuntimeSettings();

  @override
  Future<InviteAcceptResult> acceptInvite(
    InvitesRepositoryContractPrimString inviteId,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<InviteDeclineResult> declineInvite(
    InvitesRepositoryContractPrimString inviteId,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<InviteAcceptResult> acceptInviteByCode(
    InvitesRepositoryContractPrimString code,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<List<InviteContactMatch>> importContacts(
    InviteContacts contacts,
  ) async {
    return const <InviteContactMatch>[];
  }

  @override
  Future<InviteShareCodeResult> createShareCode({
    required InvitesRepositoryContractPrimString eventId,
    InvitesRepositoryContractPrimString? occurrenceId,
    InvitesRepositoryContractPrimString? accountProfileId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> sendInvites(
    InvitesRepositoryContractPrimString eventId,
    InviteRecipients recipients, {
    InvitesRepositoryContractPrimString? occurrenceId,
    InvitesRepositoryContractPrimString? message,
  }) async {}

  @override
  Future<List<SentInviteStatus>> getSentInvitesForEvent(
    InvitesRepositoryContractPrimString eventId,
  ) async {
    return const <SentInviteStatus>[];
  }
}
