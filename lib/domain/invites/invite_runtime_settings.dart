import 'package:belluga_now/domain/invites/value_objects/invite_cooldowns_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_message_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_rate_limits_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/tenant_id_value.dart';

class InviteRuntimeSettings {
  const InviteRuntimeSettings({
    this.tenantIdValue,
    required this.limitValues,
    required this.cooldownValues,
    this.overQuotaMessageValue,
  });

  final TenantIdValue? tenantIdValue;
  final InviteRateLimitsValue limitValues;
  final InviteCooldownsValue cooldownValues;
  final InviteMessageValue? overQuotaMessageValue;

  String? get tenantId => tenantIdValue?.value;
  InviteRateLimitsValue get limits => limitValues;
  InviteCooldownsValue get cooldowns => cooldownValues;
  String? get overQuotaMessage => overQuotaMessageValue?.value;
}
