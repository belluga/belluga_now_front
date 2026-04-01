import 'package:belluga_now/domain/partners/profile_type_definition.dart';

class ProfileTypeDefinitions {
  ProfileTypeDefinitions() : _value = <ProfileTypeDefinition>[];

  final List<ProfileTypeDefinition> _value;

  List<ProfileTypeDefinition> get value =>
      List<ProfileTypeDefinition>.unmodifiable(_value);

  void add(ProfileTypeDefinition definition) {
    _value.add(definition);
  }
}
