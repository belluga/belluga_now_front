import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/presentation/tenant/widgets/carousel_event_card.dart';
import 'package:flutter/material.dart';

/// Hero card reusing the CarouselEventCard (Seus Eventos pattern).
class InviteEventHero extends StatelessWidget {
  const InviteEventHero({super.key, required this.invite});

  final InviteModel invite;

  @override
  Widget build(BuildContext context) {
    return CarouselEventCard(
      event: VenueEventResume(
        id: invite.eventId,
        slug: invite.eventId,
        titleValue: invite.eventNameValue,
        imageUriValue: invite.eventImageValue,
        startDateTimeValue: invite.eventDateValue,
        // Accept short venue labels from invite mocks without tripping the min length validator.
        locationValue: DescriptionValue(minLenght: 1)
          ..parse(invite.locationValue.value.isNotEmpty
              ? invite.locationValue.value
              : 'Local a definir'),
        artists: const [],
      ),
    );
  }
}
