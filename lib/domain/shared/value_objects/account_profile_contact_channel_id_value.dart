import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

/// Stable opaque identifier of a persisted contact channel.
///
/// The channel package owns channel semantics; the Account Profile aggregate
/// owns the optional pointer that selects one persisted channel for its FAB.
class AccountProfileContactChannelIdValue extends GenericStringValue {
  AccountProfileContactChannelIdValue([String raw = ''])
    : super(defaultValue: '', isRequired: true, minLenght: 1) {
    if (raw.trim().isNotEmpty) {
      parse(raw);
    }
  }
}
