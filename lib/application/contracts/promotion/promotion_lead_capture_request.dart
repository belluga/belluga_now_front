import 'package:belluga_now/application/contracts/promotion/promotion_lead_capture_field_payload.dart';
import 'package:belluga_now/domain/app_data/value_object/environment_name_value.dart';

class PromotionLeadCaptureRequest {
  PromotionLeadCaptureRequest({
    required this.appNameValue,
    required List<PromotionLeadCaptureFieldPayload> submittedFields,
  }) : submittedFields = List<PromotionLeadCaptureFieldPayload>.unmodifiable(
          submittedFields,
        );

  final EnvironmentNameValue appNameValue;
  final List<PromotionLeadCaptureFieldPayload> submittedFields;

  String get appName => appNameValue.value.trim();
}
