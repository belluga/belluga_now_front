import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/auth_backend/auth_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/favorite_backend/laravel_favorite_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/partners_backend/laravel_account_profiles_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/schedule_backend/laravel_schedule_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/production_backend/live_only_unsupported_backends.dart';
import 'package:belluga_now/infrastructure/dal/dao/production_backend/production_backend.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ProductionBackend defaults to Laravel-backed runtime adapters', () {
    final backend = ProductionBackend();

    expect(backend.auth, isA<LaravelAuthBackend>());
    expect(backend.accountProfiles, isA<LaravelAccountProfilesBackend>());
    expect(backend.favorites, isA<LaravelFavoriteBackend>());
    expect(backend.schedule, isA<LaravelScheduleBackend>());
  });

  test('ProductionBackend tenant path fails fast when adapter is missing', () {
    final backend = ProductionBackend();

    expect(backend.tenant, isA<LiveOnlyUnsupportedTenantBackend>());
    expect(() => backend.tenant.getTenant(), throwsA(isA<UnsupportedError>()));
  });

  test('ProductionBackend venue-events path fails fast when adapter is missing',
      () {
    final backend = ProductionBackend();

    expect(backend.venueEvents, isA<LiveOnlyUnsupportedVenueEventBackend>());
    expect(
      () => backend.venueEvents.fetchUpcomingEvents(),
      throwsA(isA<UnsupportedError>()),
    );
  });
}
