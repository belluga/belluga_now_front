import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/partners/services/partner_profile_config_builder.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_public_detail_path_value.dart';
import 'package:belluga_now/domain/invites/invite_partner_type.dart';
import 'package:belluga_now/domain/partner/partner_resume.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_name_value.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_tagline_value.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import '../../../support/mock_backend/mock_schedule_backend.dart';
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
      'Agenda',
    ]);
  });

  testWidgets('Location section shows map CTA copy', (tester) async {
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
      linkedAccountProfiles: const [],
      tags: const [],
    );
    final event = dto.toDomain();

    await tester.pumpWidget(
      MaterialApp(
        home: LocationSection(event: event),
      ),
    );

    expect(find.text('Ver no mapa'), findsOneWidget);
    expect(find.byKey(const Key('eventMainWazeButton')), findsOneWidget);
    expect(find.byKey(const Key('eventMainUberButton')), findsOneWidget);
    expect(
      find.byKey(const Key('eventMainOtherDirectionsButton')),
      findsOneWidget,
    );
  });

  testWidgets('Venue card shows profile button', (tester) async {
    final venue = PartnerResume(
      idValue: MongoIDValue()
        ..parse(MockScheduleBackend.generateMongoId('test-venue')),
      nameValue: InvitePartnerNameValue()..parse('Test Venue'),
      slugValue: SlugValue()..parse('test-venue'),
      type: InviteAccountProfileType.mercadoProducer,
      canOpenPublicDetailValue: _boolValue(true),
      publicDetailPathValue: AccountProfilePublicDetailPathValue(
        '/parceiro/test-venue',
      ),
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

  testWidgets('Venue card pushes partner detail route with the canonical slug',
      (tester) async {
    final venue = PartnerResume(
      idValue: MongoIDValue()
        ..parse(MockScheduleBackend.generateMongoId('test-venue-route')),
      nameValue: InvitePartnerNameValue()..parse('Venue Navegavel'),
      slugValue: null,
      type: InviteAccountProfileType.mercadoProducer,
      canOpenPublicDetailValue: _boolValue(true),
      publicDetailPathValue: AccountProfilePublicDetailPathValue(
        '/parceiro/venue-navegavel',
      ),
      taglineValue: InvitePartnerTaglineValue()..parse('Address'),
    );
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'VenueCardHostRoute',
          path: '/',
          builder: (_, __) => Scaffold(body: VenueCard(venue: venue)),
        ),
        NamedRouteDef(
          name: PartnerDetailRoute.name,
          path: '/parceiro/:slug',
          builder: (_, data) => Scaffold(
            body: Text('detail:${data.params.getString('slug')}'),
          ),
        ),
      ],
    )..ignorePopCompleters = true;

    await tester.pumpWidget(
      MaterialApp.router(
        routeInformationParser: router.defaultRouteParser(),
        routerDelegate: router.delegate(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ver perfil'));
    await tester.pumpAndSettle();

    expect(find.text('detail:venue-navegavel'), findsOneWidget);
  });

  testWidgets('Venue card hides profile button when public detail is disabled',
      (tester) async {
    final venue = PartnerResume(
      idValue: MongoIDValue()
        ..parse(MockScheduleBackend.generateMongoId('test-venue-hidden')),
      nameValue: InvitePartnerNameValue()..parse('Venue Fechado'),
      slugValue: SlugValue()..parse('venue-fechado'),
      type: InviteAccountProfileType.mercadoProducer,
      canOpenPublicDetailValue: _boolValue(false),
      publicDetailPathValue: AccountProfilePublicDetailPathValue(''),
      taglineValue: InvitePartnerTaglineValue()..parse('Address'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VenueCard(venue: venue),
        ),
      ),
    );

    expect(find.text('Ver perfil'), findsNothing);
  });

  testWidgets(
      'Venue card hides profile button when flag is true but path is empty',
      (tester) async {
    final venue = PartnerResume(
      idValue: MongoIDValue()
        ..parse(MockScheduleBackend.generateMongoId('test-venue-empty-path')),
      nameValue: InvitePartnerNameValue()..parse('Venue Sem Path'),
      slugValue: SlugValue()..parse('venue-sem-path'),
      type: InviteAccountProfileType.mercadoProducer,
      canOpenPublicDetailValue: _boolValue(true),
      publicDetailPathValue: AccountProfilePublicDetailPathValue(''),
      taglineValue: InvitePartnerTaglineValue()..parse('Address'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VenueCard(venue: venue),
        ),
      ),
    );

    expect(find.text('Ver perfil'), findsNothing);
  });
}

DomainBooleanValue _boolValue(bool raw) {
  return DomainBooleanValue(defaultValue: false, isRequired: false)
    ..parse(raw.toString());
}
