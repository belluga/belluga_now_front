import 'app_promotion_web_store_platform_resolver_stub.dart'
    if (dart.library.html) 'app_promotion_web_store_platform_resolver_web.dart'
    as web_store_platform;

import 'package:belluga_now/application/router/support/route_redirect_path.dart';
import 'package:belluga_now/application/telemetry/web_promotion_telemetry.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/controllers/app_promotion_store_platform.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';

typedef AppPromotionStorePlatformResolver = AppPromotionStorePlatform?
    Function();

class AppPromotionScreenController implements Disposable {
  AppPromotionScreenController({
    AppDataRepositoryContract? appDataRepository,
    AppPromotionStorePlatformResolver? preferredStorePlatformResolver,
  })  : _appDataRepository =
            appDataRepository ?? GetIt.I.get<AppDataRepositoryContract>(),
        _preferredStorePlatformResolver =
            preferredStorePlatformResolver ??
                web_store_platform.resolvePreferredWebPromotionStorePlatform;

  final AppDataRepositoryContract _appDataRepository;
  final AppPromotionStorePlatformResolver _preferredStorePlatformResolver;

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
    if (preferred != null) {
      return <AppPromotionStorePlatform>[preferred];
    }
    return const <AppPromotionStorePlatform>[
      AppPromotionStorePlatform.ios,
      AppPromotionStorePlatform.android,
    ];
  }

  Uri? buildAndroidPromotionUri({
    required String redirectPath,
  }) {
    return buildTenantPromotionUriFromAppContext(
      redirectPath: normalizeRedirectPath(redirectPath),
      platformTarget: 'android',
      mainDomainUri: _appDataRepository.appData.mainDomainValue.value,
    );
  }

  Uri? buildIosPromotionUri({
    required String redirectPath,
  }) {
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
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void onDispose() {}
}
