import 'package:belluga_now/infrastructure/dal/dto/deferred_link/deferred_link_resolution_dto.dart';

abstract class DeferredLinkBackendContract {
  Future<DeferredLinkResolutionDto> resolveDeferredLink({
    required String platform,
    String? installReferrer,
    String? storeChannel,
  });
}
