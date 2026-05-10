import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

class TenantAdminPushStatus {
  TenantAdminPushStatus({
    required this.statusValue,
  });

  static const String activeStatus = 'active';
  static const String pendingTestsStatus = 'pending_tests';
  static const String notConfiguredStatus = 'not_configured';

  final TenantAdminRequiredTextValue statusValue;

  String get status => statusValue.value;

  bool get isActive => status == activeStatus;
  bool get isPendingTests => status == pendingTestsStatus;
  bool get isNotConfigured => status == notConfiguredStatus;
}
