import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/services/partner_profile_config_builder.dart';
import 'package:belluga_now/infrastructure/dal/dao/mock_backend/mock_schedule_backend.dart';
import 'package:belluga_now/infrastructure/dal/dto/mappers/artist_dto_mapper.dart';
import 'package:belluga_now/infrastructure/dal/dto/mappers/invite_dto_mapper.dart';
import 'package:belluga_now/infrastructure/dal/dto/mappers/invite_status_dto_mapper.dart';
import 'package:belluga_now/infrastructure/dal/dto/mappers/partner_dto_mapper.dart';
import 'package:belluga_now/infrastructure/dal/dto/mappers/schedule_dto_mapper.dart';
import 'package:belluga_now/infrastructure/dal/dto/mappers/thumb_dto_mapper.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_artist_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_type_dto.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_detail_screen/widgets/venue_card.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/immersive_event_detail/widgets/location_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'support/integration_test_bootstrap.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  IntegrationTestBootstrap.ensureNonProductionLandlordDomain();
  final scheduleDtoMapper = _TestScheduleDtoMapper();
  final partnerDtoMapper = _TestPartnerDtoMapper();

  testWidgets('Venue profile config uses reduced tabs', (tester) async {
    final partner = AccountProfileModel.fromPrimitives(
      id: MockScheduleBackend.generateMongoId('venue-1'),
      name: 'Test Venue',
      slug: 'test-venue',
      type: 'venue',
      bio: 'Bio for venue',
    );
    final config = PartnerProfileConfigBuilder().build(partner);

    expect(config.tabs.map((t) => t.title).toList(), [
      'Sobre',
      'Como Chegar',
      'Eventos',
    ]);
  });

  testWidgets('Location section shows venue profile CTA', (tester) async {
    final dto = EventDTO(
      id: MockScheduleBackend.generateMongoId('event-1'),
      slug: 'event-1',
      type: EventTypeDTO(
        id: '507f1f77bcf86cd799439011',
        name: 'Show',
        slug: 'show',
        description: 'Show description',
        icon: 'music',
        color: '#000000',
      ),
      title: 'Test Event',
      content: 'Test event content for location section.',
      location: 'Test Venue Address',
      venue: {
        'id': MockScheduleBackend.generateMongoId('test-venue'),
        'display_name': 'Test Venue',
        'tagline': 'Address',
        'slug': 'test-venue',
      },
      dateTimeStart: DateTime.now().toIso8601String(),
      dateTimeEnd: DateTime.now()
          .add(const Duration(hours: 2))
          .toIso8601String(),
      artists: <EventArtistDTO>[],
      tags: const [],
    );
    final event = scheduleDtoMapper.mapEventDto(dto);

    await tester.pumpWidget(
      MaterialApp(
        home: LocationSection(event: event),
      ),
    );

    expect(find.text('Ver perfil do local'), findsOneWidget);
  });

  testWidgets('Venue card shows profile button', (tester) async {
    final venue = partnerDtoMapper.mapPartnerResume({
      'id': MockScheduleBackend.generateMongoId('test-venue'),
      'display_name': 'Test Venue',
      'tagline': 'Address',
      'slug': 'test-venue',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VenueCard(venue: venue),
        ),
      ),
    );

    expect(find.text('Ver perfil'), findsOneWidget);
  });
}

class _TestScheduleDtoMapper
    with
        InviteDtoMapper,
        ThumbDtoMapper,
        ArtistDtoMapper,
        PartnerDtoMapper,
        InviteStatusDtoMapper,
        ScheduleDtoMapper {}

class _TestPartnerDtoMapper with PartnerDtoMapper {}