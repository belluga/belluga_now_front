import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/domain/venue_event/value_objects/venue_event_tag_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/presentation/tenant_public/widgets/carousel_card.dart';
import 'package:belluga_now/presentation/tenant_public/widgets/event_details.dart';
import 'package:flutter/material.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

/// Hero card reusing the CarouselEventCard (Seus Eventos pattern).
class InviteEventHero extends StatelessWidget {
  const InviteEventHero({super.key, required this.invite});

  final InviteModel invite;

  @override
  Widget build(BuildContext context) {
    final slugValue = SlugValue()..parse(invite.eventId);
    final idValue = MongoIDValue(defaultValue: _coerceMongoId(invite.eventId))
      ..parse(_coerceMongoId(invite.eventId));
    final tagValues = invite.tags
        .map((tag) => VenueEventTagValue(tag))
        .toList(growable: false);

    return CarouselCard(
      imageUri: invite.eventImageValue.value,
      contentOverlay: EventDetails(
          event: VenueEventResume(
        idValue: idValue,
        slugValue: slugValue,
        titleValue: invite.eventNameValue,
        imageUriValue: invite.eventImageValue,
        startDateTimeValue: invite.eventDateValue,
        // Accept short venue labels from invite mocks without tripping the min length validator.
        locationValue: DescriptionValue(minLenght: 1)
          ..parse(invite.locationValue.value.isNotEmpty
              ? invite.locationValue.value
              : 'Local a definir'),
        artists: const [],
        tagValues: tagValues,
      )),
    );
  }

  String _coerceMongoId(String raw) {
    final normalized = raw.trim();
    if (RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(normalized)) {
      return normalized;
    }
    return '000000000000000000000000';
  }
}
