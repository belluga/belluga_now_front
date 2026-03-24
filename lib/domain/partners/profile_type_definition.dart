import 'package:belluga_now/domain/partners/profile_type_capabilities.dart';
import 'package:belluga_now/domain/partners/value_objects/profile_type_key_value.dart';
import 'package:belluga_now/domain/partners/value_objects/profile_type_label_value.dart';

class ProfileTypeDefinition {
  ProfileTypeDefinition({
    required this.typeValue,
    required this.labelValue,
    required this.capabilities,
  });

  final ProfileTypeKeyValue typeValue;
  final ProfileTypeLabelValue labelValue;
  final ProfileTypeCapabilities capabilities;

  String get type => typeValue.value;
  String get label => labelValue.value;
}
