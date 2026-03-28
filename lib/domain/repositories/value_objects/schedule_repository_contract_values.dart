import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';
import 'package:value_object_pattern/value_object.dart';

class ScheduleRepositoryContractTextValue extends GenericStringValue {
  ScheduleRepositoryContractTextValue({
    super.defaultValue = '',
    super.isRequired = false,
    super.maxLenght,
    super.minLenght,
  });

  factory ScheduleRepositoryContractTextValue.fromRaw(
    Object? raw, {
    String defaultValue = '',
    bool isRequired = false,
  }) {
    final value = ScheduleRepositoryContractTextValue(
      defaultValue: defaultValue,
      isRequired: isRequired,
    );
    final normalized = (raw as String?)?.trim();
    value.parse(normalized);
    return value;
  }

  @override
  String doParse(String? parseValue) {
    return (parseValue ?? '').trim();
  }
}

class ScheduleRepositoryContractIntValue extends ValueObject<int> {
  ScheduleRepositoryContractIntValue({
    super.defaultValue = 0,
    super.isRequired = true,
  });

  factory ScheduleRepositoryContractIntValue.fromRaw(
    Object? raw, {
    int defaultValue = 0,
    bool isRequired = true,
  }) {
    final value = ScheduleRepositoryContractIntValue(
      defaultValue: defaultValue,
      isRequired: isRequired,
    );
    if (raw is int) {
      value.set(raw);
      return value;
    }
    value.parse(raw?.toString());
    return value;
  }

  @override
  int doParse(String? parseValue) {
    final parsed = int.tryParse((parseValue ?? '').trim());
    if (parsed == null || parsed < 0) {
      return defaultValue;
    }
    return parsed;
  }
}

class ScheduleRepositoryContractBoolValue extends ValueObject<bool> {
  ScheduleRepositoryContractBoolValue({
    super.defaultValue = false,
    super.isRequired = true,
  });

  factory ScheduleRepositoryContractBoolValue.fromRaw(
    Object? raw, {
    bool defaultValue = false,
    bool isRequired = true,
  }) {
    final value = ScheduleRepositoryContractBoolValue(
      defaultValue: defaultValue,
      isRequired: isRequired,
    );
    if (raw is bool) {
      value.set(raw);
      return value;
    }
    value.parse(raw?.toString());
    return value;
  }

  @override
  bool doParse(String? parseValue) {
    final normalized = (parseValue ?? '').trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == '0') {
      return false;
    }
    return defaultValue;
  }
}

class ScheduleRepositoryContractDoubleValue extends ValueObject<double> {
  ScheduleRepositoryContractDoubleValue({
    super.defaultValue = 0,
    super.isRequired = false,
  });

  factory ScheduleRepositoryContractDoubleValue.fromRaw(
    Object? raw, {
    double defaultValue = 0,
    bool isRequired = false,
  }) {
    final value = ScheduleRepositoryContractDoubleValue(
      defaultValue: defaultValue,
      isRequired: isRequired,
    );
    if (raw is double) {
      value.set(raw);
      return value;
    }
    value.parse(raw?.toString());
    return value;
  }

  @override
  double doParse(String? parseValue) {
    final parsed = double.tryParse((parseValue ?? '').trim());
    if (parsed == null) {
      return defaultValue;
    }
    return parsed;
  }
}

class ScheduleRepositoryContractDateTimeValue extends ValueObject<DateTime> {
  ScheduleRepositoryContractDateTimeValue({
    required DateTime defaultValue,
    super.isRequired = true,
  }) : super(defaultValue: defaultValue);

  factory ScheduleRepositoryContractDateTimeValue.fromRaw(
    Object? raw, {
    DateTime? defaultValue,
    bool isRequired = true,
  }) {
    final effectiveDefault =
        defaultValue ?? DateTime.fromMillisecondsSinceEpoch(0);
    final value = ScheduleRepositoryContractDateTimeValue(
      defaultValue: effectiveDefault,
      isRequired: isRequired,
    );
    if (raw is DateTime) {
      value.set(raw);
      return value;
    }
    value.parse(raw?.toString());
    return value;
  }

  @override
  DateTime doParse(dynamic parseValue) {
    if (parseValue is DateTime) {
      return parseValue;
    }
    final parsed = DateTime.tryParse((parseValue ?? '').toString().trim());
    if (parsed == null) {
      return defaultValue;
    }
    return parsed;
  }
}

class ScheduleRepositoryContractTaxonomyEntry {
  ScheduleRepositoryContractTaxonomyEntry({
    required this.type,
    required this.term,
  });

  factory ScheduleRepositoryContractTaxonomyEntry.fromRaw({
    Object? type,
    Object? term,
  }) {
    return ScheduleRepositoryContractTaxonomyEntry(
      type: ScheduleRepositoryContractTextValue.fromRaw(type),
      term: ScheduleRepositoryContractTextValue.fromRaw(term),
    );
  }

  final ScheduleRepositoryContractTextValue type;
  final ScheduleRepositoryContractTextValue term;

  Map<String, String> toBackendMap() {
    return <String, String>{
      'type': type.value,
      'term': term.value,
    };
  }
}
