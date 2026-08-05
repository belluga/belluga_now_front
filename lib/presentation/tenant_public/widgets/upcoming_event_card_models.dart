import 'package:flutter/material.dart';

typedef UpcomingEventCounterpartData = ({
  String label,
  String? thumbUrl,
  IconData fallbackIcon,
});

class UpcomingEventCardData {
  const UpcomingEventCardData({
    required this.imageUri,
    required this.headline,
    required this.metaLabel,
    required this.counterparts,
    required this.venueName,
    this.counterpartCount,
    this.venueDistanceLabel,
    this.venueAddress,
  });

  final Uri? imageUri;
  final String headline;
  final String metaLabel;
  final List<UpcomingEventCounterpartData> counterparts;
  final String? venueName;
  final int? counterpartCount;
  final String? venueDistanceLabel;
  final String? venueAddress;

  int get totalCounterpartCount {
    final previewCount = counterparts.length;
    final canonicalCount = counterpartCount ?? previewCount;
    return canonicalCount < previewCount ? previewCount : canonicalCount;
  }
}
