import 'package:flutter/material.dart';

class LandlordLandingInstance {
  const LandlordLandingInstance({
    required this.name,
    required this.domain,
    required this.primaryColor,
    required this.isActive,
    this.logoUrl,
  });

  final String name;
  final String domain;
  final Color primaryColor;
  final bool isActive;
  final String? logoUrl;
}
