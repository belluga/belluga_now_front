import 'package:belluga_now/domain/repositories/telemetry_repository_contract_property.dart';

class TelemetryRepositoryContractProperties {
  TelemetryRepositoryContractProperties([
    List<TelemetryRepositoryContractProperty> properties = const [],
  ]) : _properties =
           List<TelemetryRepositoryContractProperty>.unmodifiable(properties);

  final List<TelemetryRepositoryContractProperty> _properties;

  List<TelemetryRepositoryContractProperty> get properties => _properties;

  bool get isEmpty => _properties.isEmpty;
}
