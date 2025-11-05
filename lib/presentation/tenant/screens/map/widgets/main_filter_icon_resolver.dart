import 'package:flutter/material.dart';

IconData resolveMainFilterIcon(String iconName) {
  const iconMap = <String, IconData>{
    'local_offer': Icons.local_offer_outlined,
    'event': Icons.event,
    'music_note': Icons.music_note,
    'map': Icons.map_outlined,
    'restaurant': Icons.restaurant_menu,
    'festival': Icons.festival_outlined,
  };

  return iconMap[iconName] ?? Icons.filter_alt_outlined;
}
