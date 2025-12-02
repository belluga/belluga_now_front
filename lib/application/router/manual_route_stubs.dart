import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/presentation/tenant/map/routes/city_map_route.dart';
import 'package:belluga_now/presentation/tenant/map/routes/poi_details_route.dart';
import 'package:belluga_now/presentation/tenant/invites/routes/invite_flow_route.dart';
import 'package:belluga_now/presentation/tenant/invites/routes/invite_share_route.dart';

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

class InviteFlowRoute extends PageRouteInfo<void> {
  const InviteFlowRoute({List<PageRouteInfo>? children})
      : super(InviteFlowRoute.name, initialChildren: children);

  static const String name = 'InviteFlowRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) => const InviteFlowRoutePage(),
  );
}

class InviteShareRoute extends PageRouteInfo<InviteShareRouteArgs> {
  InviteShareRoute({
    required InviteModel invite,
    List<PageRouteInfo>? children,
  }) : super(
          InviteShareRoute.name,
          args: InviteShareRouteArgs(invite: invite),
          initialChildren: children,
        );

  static const String name = 'InviteShareRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<InviteShareRouteArgs>();
      return InviteShareRoutePage(
        invite: args.invite,
      );
    },
  );
}

class InviteShareRouteArgs {
  InviteShareRouteArgs({
    required this.invite,
  });

  final InviteModel invite;
}
