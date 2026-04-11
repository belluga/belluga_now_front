import 'package:belluga_now/application/router/support/canonical_route_family.dart';

const canonicalRouteHistoryMarkerKey = 'canonicalBackHistory';
const canonicalRouteHistoryVersionKey = 'v';
const canonicalRouteHistoryFamilyKey = 'family';
const canonicalRouteHistoryStageKey = 'stage';

final class CanonicalRouteHistoryState {
  const CanonicalRouteHistoryState({
    required this.family,
    required this.stageId,
  });

  final CanonicalRouteFamily family;
  final String stageId;

  Map<String, dynamic> toPathState() {
    return <String, dynamic>{
      canonicalRouteHistoryMarkerKey: true,
      canonicalRouteHistoryVersionKey: 1,
      canonicalRouteHistoryFamilyKey: family.name,
      canonicalRouteHistoryStageKey: stageId,
    };
  }

  static CanonicalRouteHistoryState? fromPathState(Object? pathState) {
    if (pathState is! Map) {
      return null;
    }
    final marker = pathState[canonicalRouteHistoryMarkerKey];
    if (marker != true) {
      return null;
    }
    final rawFamily = pathState[canonicalRouteHistoryFamilyKey];
    final rawStage = pathState[canonicalRouteHistoryStageKey];
    if (rawFamily is! String || rawStage is! String || rawStage.isEmpty) {
      return null;
    }

    final family =
        CanonicalRouteFamily.values.cast<CanonicalRouteFamily?>().firstWhere(
              (value) => value?.name == rawFamily,
              orElse: () => null,
            );
    if (family == null) {
      return null;
    }

    return CanonicalRouteHistoryState(
      family: family,
      stageId: rawStage,
    );
  }
}
