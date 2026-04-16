import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/favorite_section/controllers/favorites_section_controller.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/favorite_section/favorites_section_view.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class FavoritesSectionBuilder extends StatefulWidget {
  const FavoritesSectionBuilder({
    super.key,
  });

  @override
  State<FavoritesSectionBuilder> createState() =>
      _FavoritesSectionBuilderState();
}

class _FavoritesSectionBuilderState extends State<FavoritesSectionBuilder> {
  late final FavoritesSectionController _controller =
      GetIt.I.get<FavoritesSectionController>();

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  void dispose() {
    _controller.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FavoritesSectionView(controller: _controller);
  }
}
