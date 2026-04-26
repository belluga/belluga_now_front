import 'package:belluga_now/presentation/landlord_area/home/screens/landlord_home_screen/controllers/landlord_landing_brand.dart';
import 'package:belluga_now/presentation/landlord_area/home/screens/landlord_home_screen/controllers/landlord_landing_instance.dart';
import 'package:flutter/material.dart';

class LandlordHomeUiState {
  const LandlordHomeUiState({
    required this.tenants,
    required this.hasValidSession,
    required this.isLandlordMode,
    required this.brand,
    required this.instances,
    required this.isScrolled,
    required this.isMobileMenuOpen,
  });

  factory LandlordHomeUiState.initial() => const LandlordHomeUiState(
        tenants: <String>[],
        hasValidSession: false,
        isLandlordMode: false,
        brand: LandlordLandingBrand(
          appName: 'Bóora!',
          primary: LandlordHomeUiState.emeraldPrimary,
          secondary: LandlordHomeUiState.orangeAccent,
          accent: LandlordHomeUiState.orangeAccent,
          rose: LandlordHomeUiState.roseAccent,
          slate: LandlordHomeUiState.slateDark,
          background: LandlordHomeUiState.slateBackground,
        ),
        instances: <LandlordLandingInstance>[],
        isScrolled: false,
        isMobileMenuOpen: false,
      );

  static const Color slateBackground = Color(0xFFF8FAFC);
  static const Color slateDark = Color(0xFF0F172A);
  static const Color emeraldPrimary = Color(0xFF10B981);
  static const Color orangeAccent = Color(0xFFF97316);
  static const Color roseAccent = Color(0xFFEC4899);

  final List<String> tenants;
  final bool hasValidSession;
  final bool isLandlordMode;
  final LandlordLandingBrand brand;
  final List<LandlordLandingInstance> instances;
  final bool isScrolled;
  final bool isMobileMenuOpen;

  bool get canAccessAdminArea => hasValidSession && isLandlordMode;

  LandlordHomeUiState copyWith({
    List<String>? tenants,
    bool? hasValidSession,
    bool? isLandlordMode,
    LandlordLandingBrand? brand,
    List<LandlordLandingInstance>? instances,
    bool? isScrolled,
    bool? isMobileMenuOpen,
  }) {
    return LandlordHomeUiState(
      tenants: tenants ?? this.tenants,
      hasValidSession: hasValidSession ?? this.hasValidSession,
      isLandlordMode: isLandlordMode ?? this.isLandlordMode,
      brand: brand ?? this.brand,
      instances: instances ?? this.instances,
      isScrolled: isScrolled ?? this.isScrolled,
      isMobileMenuOpen: isMobileMenuOpen ?? this.isMobileMenuOpen,
    );
  }
}
