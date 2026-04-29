import 'dart:collection';

import 'package:belluga_now/domain/invites/value_objects/invite_account_profile_id_value.dart';

class InviteAccountProfileIds extends IterableBase<String> {
  InviteAccountProfileIds([
    Iterable<InviteAccountProfileIdValue> values =
        const <InviteAccountProfileIdValue>[],
  ]) : _values = List<InviteAccountProfileIdValue>.unmodifiable(
          _dedupe(values),
        );

  final List<InviteAccountProfileIdValue> _values;

  List<InviteAccountProfileIdValue> get valueObjects => _values;

  @override
  Iterator<String> get iterator => _values.map((value) => value.value).iterator;

  static List<InviteAccountProfileIdValue> _dedupe(
    Iterable<InviteAccountProfileIdValue> values,
  ) {
    final seen = <String>{};
    final result = <InviteAccountProfileIdValue>[];
    for (final value in values) {
      if (value.value.trim().isEmpty || !seen.add(value.value)) {
        continue;
      }
      result.add(value);
    }
    return result;
  }
}
