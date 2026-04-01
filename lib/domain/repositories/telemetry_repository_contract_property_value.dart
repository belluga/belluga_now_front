import 'package:belluga_now/domain/repositories/telemetry_repository_contract_properties.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_bool_value.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_double_value.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_int_value.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_text_value.dart';

class TelemetryRepositoryContractPropertyValue {
  const TelemetryRepositoryContractPropertyValue.text(
    TelemetryRepositoryContractTextValue value,
  )   : _textValue = value,
        _boolValue = null,
        _intValue = null,
        _doubleValue = null,
        _objectValue = null,
        _listValue = null;

  const TelemetryRepositoryContractPropertyValue.boolean(
    TelemetryRepositoryContractBoolValue value,
  )   : _textValue = null,
        _boolValue = value,
        _intValue = null,
        _doubleValue = null,
        _objectValue = null,
        _listValue = null;

  const TelemetryRepositoryContractPropertyValue.integer(
    TelemetryRepositoryContractIntValue value,
  )   : _textValue = null,
        _boolValue = null,
        _intValue = value,
        _doubleValue = null,
        _objectValue = null,
        _listValue = null;

  const TelemetryRepositoryContractPropertyValue.decimal(
    TelemetryRepositoryContractDoubleValue value,
  )   : _textValue = null,
        _boolValue = null,
        _intValue = null,
        _doubleValue = value,
        _objectValue = null,
        _listValue = null;

  const TelemetryRepositoryContractPropertyValue.object(
    TelemetryRepositoryContractProperties value,
  )   : _textValue = null,
        _boolValue = null,
        _intValue = null,
        _doubleValue = null,
        _objectValue = value,
        _listValue = null;

  const TelemetryRepositoryContractPropertyValue.list(
    List<TelemetryRepositoryContractPropertyValue> value,
  )   : _textValue = null,
        _boolValue = null,
        _intValue = null,
        _doubleValue = null,
        _objectValue = null,
        _listValue = value;

  final TelemetryRepositoryContractTextValue? _textValue;
  final TelemetryRepositoryContractBoolValue? _boolValue;
  final TelemetryRepositoryContractIntValue? _intValue;
  final TelemetryRepositoryContractDoubleValue? _doubleValue;
  final TelemetryRepositoryContractProperties? _objectValue;
  final List<TelemetryRepositoryContractPropertyValue>? _listValue;

  TelemetryRepositoryContractTextValue? get textValue => _textValue;
  TelemetryRepositoryContractBoolValue? get boolValue => _boolValue;
  TelemetryRepositoryContractIntValue? get intValue => _intValue;
  TelemetryRepositoryContractDoubleValue? get doubleValue => _doubleValue;
  TelemetryRepositoryContractProperties? get objectValue => _objectValue;
  List<TelemetryRepositoryContractPropertyValue>? get listValue => _listValue;
}
