import 'package:belluga_now/application/contracts/promotion/promotion_lead_capture_request.dart';

abstract class PromotionLeadCaptureServiceContract {
  Future<void> submitTesterWaitlistLead(
    PromotionLeadCaptureRequest request,
  );
}
