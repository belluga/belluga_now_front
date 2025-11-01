import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/presentation/tenant/screens/map/city_map_route.dart';
import 'package:belluga_now/presentation/tenant/screens/map/poi_details_route.dart';

class CityMapRoute extends PageRouteInfo<void> {
  const CityMapRoute({List<PageRouteInfo>? children})
      : super(CityMapRoute.name, initialChildren: children);

  static const String name = 'CityMapRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) => const CityMapRoutePage(),
  );
}

class PoiDetailsRoute extends PageRouteInfo<PoiDetailsRouteArgs> {
  PoiDetailsRoute({required CityPoiModel poi, List<PageRouteInfo>? children})
      : super(
          PoiDetailsRoute.name,
          args: PoiDetailsRouteArgs(poi: poi),
          initialChildren: children,
        );

  static const String name = 'PoiDetailsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PoiDetailsRouteArgs>();
      return PoiDetailsRoutePage(poi: args.poi);
    },
  );
}

class PoiDetailsRouteArgs {
  PoiDetailsRouteArgs({required this.poi});

  final CityPoiModel poi;
}
