import 'package:belluga_now/infrastructure/services/dal/dao/favorite_backend_contract.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/favorite/favorite_preview_dto.dart';
import 'package:flutter/material.dart';

class MockFavoriteBackend extends FavoriteBackendContract {
  static final List<FavoritePreviewDTO> _favorites = [
    FavoritePreviewDTO.withBadgeIcon(
      id: 'favorite-guarapari',
      title: 'Guarapari',
      assetPath: 'assets/images/logo_profile.png',
      badgeIcon: Icons.location_pin,
      isPrimary: true,
    ),
    FavoritePreviewDTO.withBadgeIcon(
      id: 'favorite-labrise',
      title: 'La Brise',
      imageUrl:
          'https://images.unsplash.com/photo-1555993539-1732b0258235?w=400',
      badgeIcon: Icons.restaurant,
    ),
    FavoritePreviewDTO.withBadgeIcon(
      id: 'favorite-sunset-club',
      title: 'Sunset Club',
      imageUrl:
          'https://images.unsplash.com/photo-1519677100203-7a46d19cd819?w=400',
      badgeIcon: Icons.local_activity,
    ),
    FavoritePreviewDTO.withBadgeIcon(
      id: 'favorite-dj-horizonte',
      title: 'DJ Horizonte',
      imageUrl:
          'https://images.unsplash.com/photo-1464375117522-1311d6a5b81f?w=400',
      badgeIcon: Icons.music_note,
    ),
    FavoritePreviewDTO.withBadgeIcon(
      id: 'favorite-banda-eclipse',
      title: 'Banda Eclipse',
      imageUrl:
          'https://images.unsplash.com/photo-1489515217757-5fd1be406fef?w=400',
      badgeIcon: Icons.queue_music,
    ),
    FavoritePreviewDTO.withBadgeIcon(
      id: 'favorite-chef-paula',
      title: 'Chef Paula',
      imageUrl:
          'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=400',
      badgeIcon: Icons.restaurant_menu,
    ),
  ];

  @override
  Future<List<FavoritePreviewDTO>> fetchFavorites() async {
    return List<FavoritePreviewDTO>.unmodifiable(_favorites);
  }
}
