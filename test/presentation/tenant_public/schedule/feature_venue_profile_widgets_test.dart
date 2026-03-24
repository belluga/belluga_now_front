import 'package:belluga_now/domain/partners/services/partner_profile_config_builder.dart';
import 'package:belluga_now/domain/invites/invite_partner_type.dart';
import 'package:belluga_now/domain/partner/partner_resume.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_name_value.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_tagline_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import '../../../support/mock_backend/mock_schedule_backend.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_artist_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_type_dto.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/widgets/location_section.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/widgets/venue_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:belluga_now/testing/account_profile_model_factory.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Venue profile config uses reduced tabs', (tester) async {
    final partner = buildAccountProfileModelFromPrimitives(
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
      dateTimeEnd:
          DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
      artists: <EventArtistDTO>[],
      tags: const [],
    );
    final event = dto.toDomain();

    await tester.pumpWidget(
      MaterialApp(
        home: LocationSection(event: event),
      ),
    );

    expect(find.text('Ver perfil do local'), findsOneWidget);
  });

  testWidgets('Venue card shows profile button', (tester) async {
    final venue = PartnerResume(
      idValue:
          MongoIDValue()..parse(MockScheduleBackend.generateMongoId('test-venue')),
      nameValue: InvitePartnerNameValue()..parse('Test Venue'),
      slugValue: SlugValue()..parse('test-venue'),
      type: InviteAccountProfileType.mercadoProducer,
      taglineValue: InvitePartnerTaglineValue()..parse('Address'),
    );

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
