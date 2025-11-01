import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant/screens/map/city_map_route.dart';

class CityMapRoute extends PageRouteInfo<void> {
  const CityMapRoute({List<PageRouteInfo>? children})
      : super(CityMapRoute.name, initialChildren: children);

  static const String name = 'CityMapRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) => const CityMapRoutePage(),
  );
}
