class UserDtoLabels {

  const UserDtoLabels();

  static const String id = "id";
  static const String profile = "profile";
  static const String customData = "custom_data";
  static const profileLabels = _UserDtoLabelsProfile();
}

class _UserDtoLabelsProfile {

  const _UserDtoLabelsProfile();

  String get email => "email";
  String get name => "name";
  String get firstName => "first_name";
  String get lastName => "last_name";
  String get birthday => "birthday";
  String get gender => "gender";
  String get pictureUrl => "pictureUrl";
}