import 'package:belluga_now/domain/app_data/value_object/environment_name_value.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_email_value.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_phone_value.dart';
import 'package:belluga_now/domain/promotion/promotion_lead_mobile_platform.dart';

class PromotionLeadCaptureRequest {
  const PromotionLeadCaptureRequest({
    required this.appNameValue,
    required this.emailValue,
    required this.whatsappValue,
    required this.mobilePlatform,
  });

  final EnvironmentNameValue appNameValue;
  final ContactEmailValue emailValue;
  final ContactPhoneValue whatsappValue;
  final PromotionLeadMobilePlatform mobilePlatform;

  String get appName => appNameValue.value.trim();
  String get email => emailValue.value.trim();
  String get whatsapp => whatsappValue.value.trim();
}
