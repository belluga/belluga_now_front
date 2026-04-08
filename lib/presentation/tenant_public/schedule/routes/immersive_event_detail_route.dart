import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/schedule_module.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/shared/widgets/image_palette_theme.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/immersive_event_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'ImmersiveEventDetailRoute')
class ImmersiveEventDetailRoutePage extends ResolverRoute<EventModel, ScheduleModule> {
  const ImmersiveEventDetailRoutePage({
    super.key,
    @PathParam('slug') required this.eventSlug,
  });

  final String eventSlug;

  @override
  RouteResolverParams get resolverParams => {'slug': eventSlug};

  @override
  Widget buildScreen(BuildContext context, EventModel model) {
    final fallbackImageValue = ThumbUriValue(
      defaultValue: Uri.parse('asset://event-placeholder'),
      isRequired: true,
    )..parse('asset://event-placeholder');
    final preferredImageUri = VenueEventResume.resolvePreferredImageUri(
      model,
      settingsDefaultImageValue: fallbackImageValue,
    );
    if (preferredImageUri.scheme == 'asset') {
      return ImmersiveEventDetailScreen(
        event: model,
      );
    }
    return ImagePaletteTheme(
      imageProvider: NetworkImage(preferredImageUri.toString()),
      builder: (context, scheme) => ImmersiveEventDetailScreen(
        event: model,
        colorScheme: scheme,
      ),
    );
  }
}
