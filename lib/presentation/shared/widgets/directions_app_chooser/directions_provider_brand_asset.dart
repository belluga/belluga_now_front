import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_chooser_contract.dart';
import 'package:flutter/material.dart';

enum DirectionsProviderBrandAssetType { rasterImage, svg }

class DirectionsProviderBrandAsset {
  const DirectionsProviderBrandAsset({
    required this.label,
    required this.assetPath,
    required this.assetType,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.primaryLogoSize,
    required this.compactLogoSize,
    required this.microLogoSize,
    required this.sheetLogoSize,
    this.compactIconAssetPath,
    this.compactIconAssetType,
    this.compactIconSize,
    this.compactIconSourceUrl,
    this.compactLogoTint,
    this.logoTint,
    this.provider,
    required this.sourceUrl,
    required this.sourceDescriptionUrl,
  });

  final String label;
  final String assetPath;
  final DirectionsProviderBrandAssetType assetType;
  final Color backgroundColor;
  final Color foregroundColor;
  final Size primaryLogoSize;
  final Size compactLogoSize;
  final Size microLogoSize;
  final Size sheetLogoSize;
  final String? compactIconAssetPath;
  final DirectionsProviderBrandAssetType? compactIconAssetType;
  final Size? compactIconSize;
  final String? compactIconSourceUrl;
  final Color? compactLogoTint;
  final Color? logoTint;
  final DirectionsDirectProvider? provider;
  final String sourceUrl;
  final String sourceDescriptionUrl;
}
