import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/schedule_module.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/common/widgets/image_palette_theme.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/immersive_event_detail/immersive_event_detail_screen.dart';
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
    final thumb = model.thumb?.thumbUri.value;
    if (thumb == null) {
      return ImmersiveEventDetailScreen(
        event: model,
      );
    }
    return ImagePaletteTheme(
      imageProvider: NetworkImage(thumb.toString()),
      builder: (context, scheme) => ImmersiveEventDetailScreen(
        event: model,
        colorScheme: scheme,
      ),
    );
  }
}
