import 'package:belluga_now/domain/partners/profile_type_capabilities.dart';
import 'package:belluga_now/domain/partners/profile_type_visual.dart';
import 'package:belluga_now/domain/partners/value_objects/profile_type_key_value.dart';
import 'package:belluga_now/domain/partners/value_objects/profile_type_label_value.dart';

class ProfileTypeDefinition {
  ProfileTypeDefinition({
    required this.typeValue,
    required this.labelValue,
    ProfileTypeLabelValue? pluralLabelValue,
    required this.capabilities,
    this.visual,
  }) : pluralLabelValue = pluralLabelValue ?? labelValue;

  final ProfileTypeKeyValue typeValue;
  final ProfileTypeLabelValue labelValue;
  final ProfileTypeLabelValue pluralLabelValue;
  final ProfileTypeCapabilities capabilities;
  final ProfileTypeVisual? visual;

  String get type => typeValue.value;
  String get label => labelValue.value;
  String get pluralLabel => pluralLabelValue.value;
}
