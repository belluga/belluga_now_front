import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/invites/invite_friend_model.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/experiences/experience_model.dart';
import 'package:belluga_now/presentation/tenant/screens/map/city_map_route.dart';
import 'package:belluga_now/presentation/tenant/screens/map/poi_details_route.dart';
import 'package:belluga_now/presentation/tenant/screens/mercado/mercado_route.dart';
import 'package:belluga_now/presentation/tenant/screens/mercado/models/mercado_producer.dart';
import 'package:belluga_now/presentation/tenant/screens/mercado/producer_store_route.dart';
import 'package:belluga_now/presentation/tenant/screens/experiences/experiences_route.dart';
import 'package:belluga_now/presentation/tenant/screens/experiences/experience_detail_route.dart';
import 'package:belluga_now/presentation/tenant/screens/invites/invite_flow_route.dart';
import 'package:belluga_now/presentation/tenant/screens/invites/invite_share_route.dart';

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

class MercadoRoute extends PageRouteInfo<void> {
  const MercadoRoute({List<PageRouteInfo>? children})
      : super(MercadoRoute.name, initialChildren: children);

  static const String name = 'MercadoRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) => const MercadoRoutePage(),
  );
}

class ProducerStoreRoute extends PageRouteInfo<ProducerStoreRouteArgs> {
  ProducerStoreRoute({
    required MercadoProducer producer,
    List<PageRouteInfo>? children,
  }) : super(
          ProducerStoreRoute.name,
          args: ProducerStoreRouteArgs(producer: producer),
          initialChildren: children,
        );

  static const String name = 'ProducerStoreRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ProducerStoreRouteArgs>();
      return ProducerStoreRoutePage(producer: args.producer);
    },
  );
}

class ProducerStoreRouteArgs {
  ProducerStoreRouteArgs({required this.producer});

  final MercadoProducer producer;
}

class ExperiencesRoute extends PageRouteInfo<void> {
  const ExperiencesRoute({List<PageRouteInfo>? children})
      : super(ExperiencesRoute.name, initialChildren: children);

  static const String name = 'ExperiencesRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) => const ExperiencesRoutePage(),
  );
}

class ExperienceDetailRoute extends PageRouteInfo<ExperienceDetailRouteArgs> {
  ExperienceDetailRoute({
    required ExperienceModel experience,
    List<PageRouteInfo>? children,
  }) : super(
          ExperienceDetailRoute.name,
          args: ExperienceDetailRouteArgs(experience: experience),
          initialChildren: children,
        );

  static const String name = 'ExperienceDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ExperienceDetailRouteArgs>();
      return ExperienceDetailRoutePage(experience: args.experience);
    },
  );
}

class ExperienceDetailRouteArgs {
  ExperienceDetailRouteArgs({required this.experience});

  final ExperienceModel experience;
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
    required List<InviteFriendModel> friends,
    List<PageRouteInfo>? children,
  }) : super(
          InviteShareRoute.name,
          args: InviteShareRouteArgs(
            invite: invite,
            friends: friends,
          ),
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
    required this.friends,
  });

  final InviteModel invite;
  final List<InviteFriendModel> friends;
}
