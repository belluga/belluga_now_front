import 'package:value_object_pattern/domain/value_objects/email_address_value.dart';

class TenantAdminResendEmailRecipients {
  TenantAdminResendEmailRecipients([
    Iterable<EmailAddressValue>? recipientValues,
  ]) : recipientValues = List<EmailAddressValue>.unmodifiable(
          _normalize(recipientValues),
        );

  final List<EmailAddressValue> recipientValues;

  bool get isEmpty => recipientValues.isEmpty;
  int get length => recipientValues.length;

  List<EmailAddressValue> get values =>
      List<EmailAddressValue>.unmodifiable(recipientValues);

  static List<EmailAddressValue> _normalize(
    Iterable<EmailAddressValue>? rawValues,
  ) {
    if (rawValues == null) {
      return const <EmailAddressValue>[];
    }

    final normalized = <EmailAddressValue>[];
    final seen = <String>{};
    for (final value in rawValues) {
      final key = value.value.trim().toLowerCase();
      if (key.isEmpty || !seen.add(key)) {
        continue;
      }
      normalized.add(value);
    }

    return normalized;
  }
}
