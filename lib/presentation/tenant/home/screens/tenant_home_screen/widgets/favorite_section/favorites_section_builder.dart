import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/controllers/tenant_home_controller.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/favorites_strip.dart';
import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class FavoritesSectionBuilder extends StatelessWidget {
  const FavoritesSectionBuilder({
    super.key,
    required this.controller,
  });

  final TenantHomeController controller;

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<List<FavoriteResume>?>(
      streamValue: controller.favoritesStreamValue,
      onNullWidget: const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      builder: (context, favorites) {
        final all = favorites ?? const <FavoriteResume>[];
        final items = all.where((fav) => !fav.isPrimary).toList();

        final appData = GetIt.I.get<AppDataRepository>().appData;
        final mainIconUri = appData.mainIconLightUrl.value;
        final primaryColor = _parseHexColor(appData.mainColor.value);
        final pinned = FavoriteResume(
          titleValue: TitleValue()..parse(appData.nameValue.value),
          imageUriValue:
              mainIconUri != null ? ThumbUriValue(defaultValue: mainIconUri) : null,
          iconImageUrl: mainIconUri?.toString(),
          primaryColor: primaryColor,
          isPrimary: true,
        );

        return Row(
          children: [
            Expanded(
              child: FavoritesStrip(
                items: items,
                pinned: pinned,
                onPinnedTap: () {
                  // TODO(Delphi): Route to About screen once available in AutoRoute map.
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Color? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final normalized = hex.replaceAll('#', '');
    if (normalized.length != 6 && normalized.length != 8) return null;
    final value = int.tryParse(normalized.length == 6 ? 'FF$normalized' : normalized, radix: 16);
    if (value == null) return null;
    return Color(value);
  }
}
