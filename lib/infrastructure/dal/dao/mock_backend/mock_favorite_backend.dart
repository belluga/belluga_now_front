import 'package:belluga_now/infrastructure/dal/dao/favorite_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/favorite/favorite_preview_dto.dart';
import 'package:flutter/material.dart';

class MockFavoriteBackend extends FavoriteBackendContract {
  static final List<FavoritePreviewDTO> _favorites = [
    // Only the app manager (Guarapari) is favorited by default
    FavoritePreviewDTO.withBadgeIcon(
      id: 'favorite-guarapari',
      title: 'Guarapari',
      assetPath: 'assets/images/logo_profile.png',
      badgeIcon: Icons.location_pin,
      isPrimary: true,
    ),
    // All other favorites removed - users can discover and add partners
    // via the Discovery screen
  ];

  @override
  Future<List<FavoritePreviewDTO>> fetchFavorites() async {
    return List<FavoritePreviewDTO>.unmodifiable(_favorites);
  }
}
