import 'app_promotion_web_store_platform_resolver_stub.dart'
    if (dart.library.html) 'app_promotion_web_store_platform_resolver_web.dart'
    as web_store_platform;
import 'app_promotion_ios_deferred_payload_seeder_stub.dart'
    if (dart.library.html) 'app_promotion_ios_deferred_payload_seeder_web.dart'
    as ios_deferred_payload_seeder;

import 'package:belluga_now/application/router/support/route_redirect_path.dart';
import 'package:belluga_now/application/telemetry/web_promotion_telemetry.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/controllers/app_promotion_experience.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/controllers/app_promotion_store_platform.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';

typedef AppPromotionStorePlatformResolver =
    AppPromotionStorePlatform? Function();
typedef AppPromotionExperienceResolver = AppPromotionExperience Function();
typedef AppPromotionIosDeferredPayloadSeeder =
    Future<bool> Function(String payload);
typedef AppPromotionUriSupportChecker = Future<bool> Function(Uri uri);
typedef AppPromotionUriLauncher = Future<bool> Function(Uri uri);

class AppPromotionScreenController implements Disposable {
  AppPromotionScreenController({
    AppDataRepositoryContract? appDataRepository,
    AppPromotionStorePlatformResolver? preferredStorePlatformResolver,
    AppPromotionExperienceResolver? experienceResolver,
    AppPromotionIosDeferredPayloadSeeder? iosDeferredPayloadSeeder,
    AppPromotionUriSupportChecker? uriSupportChecker,
    AppPromotionUriLauncher? uriLauncher,
  }) : _appDataRepository =
           appDataRepository ?? GetIt.I.get<AppDataRepositoryContract>(),
       _preferredStorePlatformResolver =
           preferredStorePlatformResolver ??
           web_store_platform.resolvePreferredWebPromotionStorePlatform,
       _iosDeferredPayloadSeeder =
           iosDeferredPayloadSeeder ??
           ios_deferred_payload_seeder.seedIosDeferredPayloadToClipboard,
       _uriSupportChecker = uriSupportChecker ?? canLaunchUrl,
       _uriLauncher = uriLauncher ?? _launchExternalApplication,
       _experienceResolver =
           experienceResolver ?? _resolveHardcodedPromotionExperience;

  final AppDataRepositoryContract _appDataRepository;
  final AppPromotionStorePlatformResolver _preferredStorePlatformResolver;
  final AppPromotionIosDeferredPayloadSeeder _iosDeferredPayloadSeeder;
  final AppPromotionUriSupportChecker _uriSupportChecker;
  final AppPromotionUriLauncher _uriLauncher;
  final AppPromotionExperienceResolver _experienceResolver;

  AppPromotionExperience get currentExperience => _experienceResolver();

  String normalizeRedirectPath(String? rawRedirectPath) {
    final normalized = rawRedirectPath?.trim();
    if (normalized == null || normalized.isEmpty) {
      return '/';
    }
    return normalized;
  }

  String get appDisplayName {
    final normalized = _appDataRepository.appData.nameValue.value.trim();
    return normalized.isEmpty ? 'app' : normalized;
  }

  String? iconUrlForBrightness(Brightness brightness) {
    final resolved = brightness == Brightness.dark
        ? _appDataRepository.appData.mainIconDarkUrl.value
        : _appDataRepository.appData.mainIconLightUrl.value;
    final normalized = resolved?.toString().trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  List<AppPromotionStorePlatform> get storePlatformsToRender {
    final preferred = _preferredStorePlatformResolver();
    if (preferred != null && _isStorePlatformActive(preferred)) {
      return <AppPromotionStorePlatform>[preferred];
    }
    return const <AppPromotionStorePlatform>[
      AppPromotionStorePlatform.ios,
      AppPromotionStorePlatform.android,
    ].where(_isStorePlatformActive).toList(growable: false);
  }

  Uri? buildAndroidPromotionUri({required String redirectPath}) {
    if (!_isStorePlatformActive(AppPromotionStorePlatform.android)) {
      return null;
    }
    return buildTenantPromotionUriFromAppContext(
      redirectPath: normalizeRedirectPath(redirectPath),
      platformTarget: 'android',
      mainDomainUri: _appDataRepository.appData.mainDomainValue.value,
    );
  }

  Uri? buildIosPromotionUri({required String redirectPath}) {
    if (!_isStorePlatformActive(AppPromotionStorePlatform.ios)) {
      return null;
    }
    return buildTenantPromotionUriFromAppContext(
      redirectPath: normalizeRedirectPath(redirectPath),
      platformTarget: 'ios',
      mainDomainUri: _appDataRepository.appData.mainDomainValue.value,
    );
  }

  Future<void> launchPromotionUri({
    required Uri uri,
    required AppPromotionStorePlatform platform,
  }) async {
    await WebPromotionTelemetry.trackOpenAppClick(
      platformTarget: platform.platformTarget,
    );
    if (!await _uriSupportChecker(uri)) {
      return;
    }
    if (platform == AppPromotionStorePlatform.ios) {
      await _seedIosDeferredPayloadIfPossible(uri);
    }
    await _uriLauncher(uri);
  }

  @override
  void onDispose() {}

  bool _isStorePlatformActive(AppPromotionStorePlatform platform) {
    final publicationSettings = _appDataRepository.appData.publicationSettings;
    if (!publicationSettings.hasExplicitConfig) {
      return true;
    }
    return switch (platform) {
      AppPromotionStorePlatform.android =>
        publicationSettings.android.isPublished,
      AppPromotionStorePlatform.ios => publicationSettings.ios.isPublished,
    };
  }

  Future<void> _seedIosDeferredPayloadIfPossible(Uri uri) async {
    final payload = buildDeferredResolverPayloadFromPromotionUri(uri);
    if (payload == null) {
      return;
    }

    try {
      await _iosDeferredPayloadSeeder(payload);
    } catch (_) {
      // expected_control_flow: store handoff must continue even when clipboard seeding is unavailable.
    }
  }
}

AppPromotionExperience _resolveHardcodedPromotionExperience() {
  // TODO(vnext-promotion-experience-switch): move the active promotion experience selection to runtime config/backend contracts.
  return AppPromotionExperience.appDownload;
}

Future<bool> _launchExternalApplication(Uri uri) {
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
