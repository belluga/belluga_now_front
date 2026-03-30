import 'package:belluga_now/domain/repositories/telemetry_repository_contract_property_value.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_text_value.dart';

class TelemetryRepositoryContractProperty {
  const TelemetryRepositoryContractProperty({
    required this.keyValue,
    required this.value,
  });

  final TelemetryRepositoryContractTextValue keyValue;
  final TelemetryRepositoryContractPropertyValue value;
}
