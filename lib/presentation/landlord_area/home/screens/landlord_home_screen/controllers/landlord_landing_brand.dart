import 'package:flutter/material.dart';

class LandlordLandingBrand {
  const LandlordLandingBrand({
    required this.appName,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.rose,
    required this.slate,
    required this.background,
    this.logoLightUrl,
    this.logoDarkUrl,
    this.iconLightUrl,
    this.iconDarkUrl,
    this.heroImageUrl,
  });

  factory LandlordLandingBrand.fallback() {
    return const LandlordLandingBrand(
      appName: 'Bóora!',
      primary: Color(0xFF10B981),
      secondary: Color(0xFFF97316),
      accent: Color(0xFFF97316),
      rose: Color(0xFFEC4899),
      slate: Color(0xFF0F172A),
      background: Color(0xFFF8FAFC),
    );
  }

  final String appName;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color rose;
  final Color slate;
  final Color background;
  final String? logoLightUrl;
  final String? logoDarkUrl;
  final String? iconLightUrl;
  final String? iconDarkUrl;
  final String? heroImageUrl;

  String? logoUrlFor(Brightness brightness) {
    final preferred =
        brightness == Brightness.dark ? logoDarkUrl : logoLightUrl;
    return _firstNonEmpty(preferred, logoLightUrl, logoDarkUrl);
  }

  String? iconUrlFor(Brightness brightness) {
    final preferred =
        brightness == Brightness.dark ? iconDarkUrl : iconLightUrl;
    return _firstNonEmpty(preferred, iconLightUrl, iconDarkUrl);
  }

  static String? _firstNonEmpty(String? first, String? second, String? third) {
    for (final value in [first, second, third]) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }
}
