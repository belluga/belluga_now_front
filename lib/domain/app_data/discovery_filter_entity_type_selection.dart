import 'package:belluga_now/domain/app_data/value_object/app_data_discovery_filter_token_value.dart';

class AppDataDiscoveryFilterEntityTypeSelection {
  const AppDataDiscoveryFilterEntityTypeSelection({
    required this.entityKey,
    this.typeKeys = const <AppDataDiscoveryFilterTokenValue>[],
  });

  final AppDataDiscoveryFilterTokenValue entityKey;
  final List<AppDataDiscoveryFilterTokenValue> typeKeys;

  bool get isEmpty => entityKey.value.isEmpty || typeKeys.isEmpty;
}
