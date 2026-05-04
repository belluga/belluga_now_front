import 'dart:collection';

import 'package:belluga_now/domain/invites/value_objects/inviteable_reason_value.dart';

class InviteableReasons extends IterableBase<String> {
  InviteableReasons([
    Iterable<InviteableReasonValue> values = const <InviteableReasonValue>[],
  ]) : _values = List<InviteableReasonValue>.unmodifiable(_dedupe(values));

  final List<InviteableReasonValue> _values;

  List<InviteableReasonValue> get valueObjects => _values;

  @override
  Iterator<String> get iterator => _values.map((value) => value.value).iterator;

  static List<InviteableReasonValue> _dedupe(
    Iterable<InviteableReasonValue> values,
  ) {
    final seen = <String>{};
    final result = <InviteableReasonValue>[];
    for (final value in values) {
      if (value.value.trim().isEmpty || !seen.add(value.value)) {
        continue;
      }
      result.add(value);
    }
    return result;
  }
}
