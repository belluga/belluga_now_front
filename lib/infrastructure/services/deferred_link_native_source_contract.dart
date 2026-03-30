import 'package:belluga_now/infrastructure/services/deferred_link_native_payload.dart';

abstract class DeferredLinkNativeSourceContract {
  Future<DeferredLinkNativePayload?> readInstallReferrerPayload();
}
