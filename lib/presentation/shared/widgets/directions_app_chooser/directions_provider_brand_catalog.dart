import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_choice.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_chooser_contract.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_provider_brand_asset.dart';
import 'package:flutter/material.dart';

class DirectionsProviderBrandCatalog {
  const DirectionsProviderBrandCatalog._();

  static const googleMaps = DirectionsProviderBrandAsset(
    label: 'Google Maps',
    assetPath: 'assets/brands/directions/google_maps_icon_2020.svg',
    assetType: DirectionsProviderBrandAssetType.svg,
    backgroundColor: Color(0xFFFFFFFF),
    foregroundColor: Color(0xFF1F1F1F),
    primaryLogoSize: Size(34, 48),
    compactLogoSize: Size(28, 38),
    microLogoSize: Size(20, 28),
    sheetLogoSize: Size(24, 34),
    sourceUrl:
        'https://upload.wikimedia.org/wikipedia/commons/a/aa/Google_Maps_icon_%282020%29.svg',
    sourceDescriptionUrl:
        'https://commons.wikimedia.org/wiki/File:Google_Maps_icon_(2020).svg',
  );

  static const waze = DirectionsProviderBrandAsset(
    provider: DirectionsDirectProvider.waze,
    label: 'Waze',
    assetPath: 'assets/brands/directions/waze_logo_2022.png',
    assetType: DirectionsProviderBrandAssetType.rasterImage,
    backgroundColor: Color(0xFF33CCFF),
    foregroundColor: Color(0xFF101820),
    primaryLogoSize: Size(86, 25),
    compactLogoSize: Size(70, 20),
    microLogoSize: Size(30, 10),
    sheetLogoSize: Size(52, 15),
    compactIconAssetPath: 'assets/brands/directions/waze_app_icon_2026.jpg',
    compactIconAssetType: DirectionsProviderBrandAssetType.rasterImage,
    compactIconSize: Size(30, 30),
    compactIconSourceUrl:
        'https://is1-ssl.mzstatic.com/image/thumb/Purple221/v4/20/16/09/20160991-52e7-cbe5-7c99-6fd7c0539379/AppIcon-0-0-1x_U007epad-0-1-0-85-220.png/512x512bb.jpg',
    compactLogoTint: null,
    sourceUrl:
        'https://upload.wikimedia.org/wikipedia/commons/3/37/Waze_logo_2022.png',
    sourceDescriptionUrl:
        'https://commons.wikimedia.org/wiki/File:Waze_logo_2022.png',
  );

  static const uber = DirectionsProviderBrandAsset(
    provider: DirectionsDirectProvider.uber,
    label: 'Uber',
    assetPath: 'assets/brands/directions/uber_logotype.svg',
    assetType: DirectionsProviderBrandAssetType.svg,
    backgroundColor: Color(0xFF000000),
    foregroundColor: Color(0xFFFFFFFF),
    primaryLogoSize: Size(76, 16),
    compactLogoSize: Size(60, 13),
    microLogoSize: Size(28, 8),
    sheetLogoSize: Size(46, 10),
    compactIconAssetPath: 'assets/brands/directions/uber_app_icon_2026.jpg',
    compactIconAssetType: DirectionsProviderBrandAssetType.rasterImage,
    compactIconSize: Size(28, 28),
    compactIconSourceUrl:
        'https://is1-ssl.mzstatic.com/image/thumb/Purple211/v4/b0/00/4e/b0004ede-5b3e-88cd-658e-266661f04de0/AppIcon-0-0-1x_U007emarketing-0-8-0-0-85-220.png/512x512bb.jpg',
    compactLogoTint: Color(0xFF111111),
    logoTint: Color(0xFFFFFFFF),
    sourceUrl:
        'https://upload.wikimedia.org/wikipedia/commons/8/8d/Uber_logotype.svg',
    sourceDescriptionUrl:
        'https://commons.wikimedia.org/wiki/File:Uber_logotype.svg',
  );

  static const ninetyNine = DirectionsProviderBrandAsset(
    label: '99',
    assetPath: 'assets/brands/directions/99_logo_2023.png',
    assetType: DirectionsProviderBrandAssetType.rasterImage,
    backgroundColor: Color(0xFFFFFFFF),
    foregroundColor: Color(0xFF1F1F1F),
    primaryLogoSize: Size(42, 42),
    compactLogoSize: Size(34, 34),
    microLogoSize: Size(24, 24),
    sheetLogoSize: Size(34, 34),
    sourceUrl:
        'https://upload.wikimedia.org/wikipedia/commons/2/2a/99_logo.png',
    sourceDescriptionUrl: 'https://commons.wikimedia.org/wiki/File:99_logo.png',
  );

  static DirectionsProviderBrandAsset fromProvider(
    DirectionsDirectProvider provider,
  ) {
    return switch (provider) {
      DirectionsDirectProvider.waze => waze,
      DirectionsDirectProvider.uber => uber,
    };
  }

  static DirectionsProviderBrandAsset? fromVisualType(
    DirectionsAppVisualType visualType,
  ) {
    return switch (visualType) {
      DirectionsAppVisualType.googleMaps => googleMaps,
      DirectionsAppVisualType.waze => waze,
      DirectionsAppVisualType.uber => uber,
      DirectionsAppVisualType.ninetyNine => ninetyNine,
      _ => null,
    };
  }
}
