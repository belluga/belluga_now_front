export 'landlord_home_ui_state.dart';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/environment_type.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_public_instances_repository_contract.dart';
import 'package:belluga_now/presentation/landlord_area/home/screens/landlord_home_screen/controllers/landlord_home_ui_state.dart';
import 'package:belluga_now/presentation/landlord_area/home/screens/landlord_home_screen/controllers/landlord_landing_brand.dart';
import 'package:belluga_now/presentation/landlord_area/home/screens/landlord_home_screen/controllers/landlord_landing_instance.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:url_launcher/url_launcher.dart';

class LandlordHomeScreenController implements Disposable {
  LandlordHomeScreenController({
    AdminModeRepositoryContract? adminModeRepository,
    LandlordAuthRepositoryContract? landlordAuthRepository,
    AppDataRepositoryContract? appDataRepository,
    LandlordPublicInstancesRepositoryContract? publicInstancesRepository,
  })  : _adminModeRepository =
            adminModeRepository ?? GetIt.I.get<AdminModeRepositoryContract>(),
        _landlordAuthRepository = landlordAuthRepository ??
            GetIt.I.get<LandlordAuthRepositoryContract>(),
        _appDataRepository =
            appDataRepository ?? GetIt.I.get<AppDataRepositoryContract>(),
        _publicInstancesRepository = publicInstancesRepository ??
            GetIt.I.get<LandlordPublicInstancesRepositoryContract>();

  final AdminModeRepositoryContract _adminModeRepository;
  final LandlordAuthRepositoryContract _landlordAuthRepository;
  final AppDataRepositoryContract _appDataRepository;
  final LandlordPublicInstancesRepositoryContract _publicInstancesRepository;

  final StreamValue<LandlordHomeUiState> uiStateStreamValue =
      StreamValue<LandlordHomeUiState>(
    defaultValue: LandlordHomeUiState.initial(),
  );
  final ScrollController scrollController = ScrollController();
  final GlobalKey problemSectionKey = GlobalKey();
  final GlobalKey solutionSectionKey = GlobalKey();
  final GlobalKey ecosystemSectionKey = GlobalKey();
  final GlobalKey instancesSectionKey = GlobalKey();
  final GlobalKey footerSectionKey = GlobalKey();

  bool _isInitialized = false;
  bool _isDisposed = false;
  bool _featuredInstancesLoadStarted = false;
  List<AppData> _featuredInstanceEnvironments = const [];

  bool get isLandlordMode => _adminModeRepository.isLandlordMode;
  bool get hasValidSession => _landlordAuthRepository.hasValidSession;
  bool get canAccessAdminArea => hasValidSession && isLandlordMode;

  Future<void> init() async {
    if (!_isInitialized) {
      scrollController.addListener(_handleScrollChanged);
      _isInitialized = true;
    }
    await _adminModeRepository.init();
    refreshUiState();
    if (!_featuredInstancesLoadStarted) {
      _featuredInstancesLoadStarted = true;
      await _loadFeaturedInstances();
    }
  }

  void refreshUiState() {
    if (_isDisposed) {
      return;
    }
    final appData = _tryResolveAppData();
    final instances = _buildInstances();
    uiStateStreamValue.addValue(
      uiStateStreamValue.value.copyWith(
        tenants: instances.map((instance) => instance.domain).toList(),
        hasValidSession: hasValidSession,
        isLandlordMode: isLandlordMode,
        brand: _buildBrand(appData),
        instances: instances,
      ),
    );
  }

  void toggleMobileMenu() {
    final current = uiStateStreamValue.value;
    uiStateStreamValue.addValue(
      current.copyWith(isMobileMenuOpen: !current.isMobileMenuOpen),
    );
  }

  void closeMobileMenu() {
    final current = uiStateStreamValue.value;
    if (!current.isMobileMenuOpen) {
      return;
    }
    uiStateStreamValue.addValue(current.copyWith(isMobileMenuOpen: false));
  }

  Future<void> scrollToProblem() => _scrollTo(problemSectionKey);

  Future<void> scrollToSolution() => _scrollTo(solutionSectionKey);

  Future<void> scrollToEcosystem() => _scrollTo(ecosystemSectionKey);

  Future<void> scrollToInstances() => _scrollTo(instancesSectionKey);

  Future<void> scrollToFooter() => _scrollTo(footerSectionKey);

  Future<void> openInstance(LandlordLandingInstance instance) async {
    final uri = Uri.tryParse('https://${instance.domain}');
    if (uri == null) {
      return;
    }
    await launchUrl(uri, webOnlyWindowName: '_self');
  }

  Future<void> openWhatsAppContact() async {
    final uri = Uri.parse('https://wa.me/5527996419823');
    await launchUrl(uri, webOnlyWindowName: '_blank');
  }

  Future<void> _loadFeaturedInstances() async {
    try {
      _featuredInstanceEnvironments =
          await _publicInstancesRepository.fetchFeaturedInstances();
    } catch (_) {
      _featuredInstanceEnvironments = const [];
    }
    refreshUiState();
  }

  AppData? _tryResolveAppData() {
    try {
      return _appDataRepository.appData;
    } catch (_) {
      return null;
    }
  }

  LandlordLandingBrand _buildBrand(AppData? appData) {
    if (appData == null) {
      return LandlordLandingBrand.fallback();
    }

    final colorScheme = appData.themeDataSettings.themeDataLight().colorScheme;
    return LandlordLandingBrand(
      appName: appData.typeValue.value == EnvironmentType.landlord
          ? 'Bóora!'
          : _normalizeAppName(appData.nameValue.value),
      primary: _parseHexColor(appData.mainColor.value) ?? colorScheme.primary,
      secondary: colorScheme.secondary,
      accent: colorScheme.secondary,
      rose: LandlordHomeUiState.roseAccent,
      slate: LandlordHomeUiState.slateDark,
      background: LandlordHomeUiState.slateBackground,
      logoLightUrl: appData.mainLogoLightUrl.value?.toString(),
      logoDarkUrl: appData.mainLogoDarkUrl.value?.toString(),
      iconLightUrl: appData.mainIconLightUrl.value?.toString(),
      iconDarkUrl: appData.mainIconDarkUrl.value?.toString(),
    );
  }

  List<LandlordLandingInstance> _buildInstances() {
    if (_featuredInstanceEnvironments.isEmpty) {
      return const [];
    }

    return _featuredInstanceEnvironments
        .map(
          (instanceAppData) => LandlordLandingInstance(
            name: _normalizeAppName(instanceAppData.nameValue.value),
            domain: _displayHost(instanceAppData.mainDomainValue.value),
            primaryColor: _parseHexColor(instanceAppData.mainColor.value) ??
                instanceAppData.themeDataSettings
                    .themeDataLight()
                    .colorScheme
                    .primary,
            isActive: true,
            logoUrl: _firstNonEmpty(
              instanceAppData.mainLogoDarkUrl.value?.toString(),
              instanceAppData.mainLogoLightUrl.value?.toString(),
              instanceAppData.mainIconDarkUrl.value?.toString(),
            ),
          ),
        )
        .toList(growable: false);
  }

  String _displayHost(Uri uri) {
    return uri.host.trim().isEmpty ? uri.toString() : uri.host.trim();
  }

  String _normalizeAppName(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return 'Bóora!';
    }
    if (trimmed.toLowerCase().endsWith(' admin')) {
      return trimmed.substring(0, trimmed.length - 6).trim();
    }
    return trimmed;
  }

  Color? _parseHexColor(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    final normalized = value.startsWith('#') ? value.substring(1) : value;
    if (normalized.length != 6 && normalized.length != 8) {
      return null;
    }
    final parsed = int.tryParse(normalized, radix: 16);
    if (parsed == null) {
      return null;
    }
    return Color(normalized.length == 6 ? 0xFF000000 | parsed : parsed);
  }

  String? _firstNonEmpty(String? first, String? second, String? third) {
    for (final value in [first, second, third]) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }

  void _handleScrollChanged() {
    final shouldElevate =
        scrollController.hasClients && scrollController.offset > 50;
    final current = uiStateStreamValue.value;
    if (current.isScrolled == shouldElevate) {
      return;
    }
    uiStateStreamValue.addValue(current.copyWith(isScrolled: shouldElevate));
  }

  Future<void> _scrollTo(GlobalKey key) async {
    closeMobileMenu();
    final context = key.currentContext;
    if (context == null) {
      return;
    }
    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 620),
      curve: Curves.easeOutCubic,
      alignment: 0.04,
    );
  }

  @override
  void onDispose() {
    _isDisposed = true;
    scrollController.dispose();
    uiStateStreamValue.dispose();
  }
}
