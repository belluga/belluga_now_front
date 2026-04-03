import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/event_type_model.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_is_confirmed_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_type_id_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_total_confirmed_value.dart';
import 'package:belluga_now/domain/thumb/enums/thumb_types.dart';
import 'package:belluga_now/domain/thumb/thumb_model.dart';
import 'package:belluga_now/domain/value_objects/color_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_type_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/presentation/shared/widgets/image_palette_theme.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/routes/immersive_event_detail_route.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/immersive_event_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';
import 'package:value_object_pattern/domain/value_objects/html_content_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

void main() {
  testWidgets(
      'wraps immersive event detail with image palette theme when thumb exists',
      (tester) async {
    final route = const ImmersiveEventDetailRoutePage(
      eventSlug: 'show-immersive',
    );
    final event = _buildEvent(
      thumbUrl: 'https://example.com/event.png',
    );

    late Widget builtScreen;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            builtScreen = route.buildScreen(context, event);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(builtScreen, isA<ImagePaletteTheme>());
  });

  testWidgets(
      'returns plain immersive event detail screen when thumb is missing',
      (tester) async {
    final route = const ImmersiveEventDetailRoutePage(
      eventSlug: 'show-immersive',
    );
    final event = _buildEvent();

    late Widget builtScreen;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            builtScreen = route.buildScreen(context, event);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(builtScreen, isA<ImmersiveEventDetailScreen>());
  });
}

EventModel _buildEvent({
  String? thumbUrl,
}) {
  return eventModelFromRaw(
    id: MongoIDValue()..parse('507f1f77bcf86cd799439011'),
    slugValue: SlugValue()..parse('show-immersive'),
    type: EventTypeModel(
      id: EventTypeIdValue()..parse('show'),
      name: TitleValue()..parse('Show tipo'),
      slug: SlugValue()..parse('show'),
      description: DescriptionValue()..parse('Descricao longa do tipo.'),
      icon: SlugValue()..parse('music'),
      color: ColorValue(defaultValue: Colors.blue)..parse('#3366FF'),
    ),
    title: TitleValue()..parse('Evento de Teste'),
    content: HTMLContentValue()..parse('Descricao longa do evento para teste.'),
    location: DescriptionValue()..parse('Local muito legal para teste.'),
    venue: null,
    thumb: thumbUrl == null
        ? null
        : ThumbModel(
            thumbUri: ThumbUriValue(
              defaultValue: Uri.parse(thumbUrl),
            )..parse(thumbUrl),
            thumbType: ThumbTypeValue(defaultValue: ThumbTypes.image)
              ..parse(ThumbTypes.image.name),
          ),
    dateTimeStart: DateTimeValue(isRequired: true)
      ..parse(DateTime(2026, 3, 15, 20).toIso8601String()),
    dateTimeEnd: null,
    artists: const [],
    coordinate: null,
    tags: const <String>['show'],
    isConfirmedValue: EventIsConfirmedValue()..parse('false'),
    confirmedAt: null,
    receivedInvites: null,
    sentInvites: null,
    friendsGoing: null,
    totalConfirmedValue: EventTotalConfirmedValue()..parse('0'),
  );
}
