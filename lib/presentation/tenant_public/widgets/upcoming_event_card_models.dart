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
    this.venueDistanceLabel,
    this.venueAddress,
  });

  final Uri? imageUri;
  final String headline;
  final String metaLabel;
  final List<UpcomingEventCounterpartData> counterparts;
  final String? venueName;
  final String? venueDistanceLabel;
  final String? venueAddress;
}
