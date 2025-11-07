import 'package:belluga_now/infrastructure/services/dal/dao/home_backend_contract.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/home/home_event_dto.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/home/home_favorite_dto.dart';
import 'package:flutter/material.dart';

class MockHomeBackend extends HomeBackendContract {
  static final List<HomeFavoriteDTO> _favorites = [
    HomeFavoriteDTO.withBadgeIcon(
      title: 'Guarapari',
      assetPath: 'assets/images/logo_profile.png',
      badgeIcon: Icons.location_pin,
      isPrimary: true,
    ),
    HomeFavoriteDTO.withBadgeIcon(
      title: 'La Brise',
      imageUrl:
          'https://images.unsplash.com/photo-1555993539-1732b0258235?w=400',
      badgeIcon: Icons.restaurant,
    ),
    HomeFavoriteDTO.withBadgeIcon(
      title: 'Sunset Club',
      imageUrl:
          'https://images.unsplash.com/photo-1519677100203-7a46d19cd819?w=400',
      badgeIcon: Icons.local_activity,
    ),
    HomeFavoriteDTO.withBadgeIcon(
      title: 'DJ Horizonte',
      imageUrl:
          'https://images.unsplash.com/photo-1464375117522-1311d6a5b81f?w=400',
      badgeIcon: Icons.music_note,
    ),
    HomeFavoriteDTO.withBadgeIcon(
      title: 'Banda Eclipse',
      imageUrl:
          'https://images.unsplash.com/photo-1489515217757-5fd1be406fef?w=400',
      badgeIcon: Icons.queue_music,
    ),
    HomeFavoriteDTO.withBadgeIcon(
      title: 'Chef Paula',
      imageUrl:
          'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=400',
      badgeIcon: Icons.restaurant_menu,
    ),
  ];

  static final List<HomeEventDTO> _featuredEvents = [
    HomeEventDTO(
      id: 'event-day0-morning-flow',
      title: 'Festival de Verao',
      imageUrl:
          'https://images.unsplash.com/photo-1524368535928-5b5e00ddc76b?w=800',
      startDateTime: DateTime(2024, 1, 7, 20, 0),
      location: 'Praia do Morro',
      artist: 'DJ Mare Alta',
    ),
    HomeEventDTO(
      id: 'event-day0-sunset-acoustic',
      title: 'Luau Exclusivo',
      imageUrl:
          'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=800',
      startDateTime: DateTime(2024, 1, 8, 22, 0),
      location: 'Areia Preta',
      artist: 'Banda Eclipse',
    ),
    HomeEventDTO(
      id: 'event-day0-electro-sunset',
      title: 'Sunset Experience',
      imageUrl:
          'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=800',
      startDateTime: DateTime(2024, 1, 9, 18, 0),
      location: 'Parque da Areia',
      artist: 'DJ Horizonte',
    ),
  ];

  static final List<HomeEventDTO> _upcomingEvents = [
    HomeEventDTO(
      id: 'event-day1-coffee-lab',
      title: 'Circuito Gastronomico',
      imageUrl:
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800',
      startDateTime: DateTime(2024, 1, 12, 19, 30),
      location: 'Bistro da Orla',
      artist: 'Chef Paula Figueiredo',
    ),
    HomeEventDTO(
      id: 'event-day1-coastal-run',
      title: 'Passeio de Escuna',
      imageUrl:
          'https://images.unsplash.com/photo-1493558103817-58b2924bce98?w=800',
      startDateTime: DateTime(2024, 1, 13, 9, 0),
      location: 'Porto da Barra',
      artist: 'Guia Clara Nunes',
    ),
    HomeEventDTO(
      id: 'event-day1-artisan-stage',
      title: 'Tour Historico a Pe',
      imageUrl:
          'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=800',
      startDateTime: DateTime(2024, 1, 14, 15, 0),
      location: 'Centro Historico',
      artist: 'Historiador Joao Mendes',
    ),
  ];

  @override
  Future<List<HomeFavoriteDTO>> fetchFavorites() async {
    return List<HomeFavoriteDTO>.unmodifiable(_favorites);
  }

  @override
  Future<List<HomeEventDTO>> fetchFeaturedEvents() async {
    return List<HomeEventDTO>.unmodifiable(_featuredEvents);
  }

  @override
  Future<List<HomeEventDTO>> fetchUpcomingEvents() async {
    return List<HomeEventDTO>.unmodifiable(_upcomingEvents);
  }
}
