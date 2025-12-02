class UserProfileDto {
  final String? name;
  final String? email;
  final String? pictureUrl;
  final String? birthday;

  UserProfileDto({
    this.name,
    this.email,
    this.pictureUrl,
    this.birthday,
  });

  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    return UserProfileDto(
      name: json['name'] as String?,
      email: json['email'] as String?,
      pictureUrl: json['picture_url'] as String?,
      birthday: json['birthday'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'picture_url': pictureUrl,
      'birthday': birthday,
    };
  }
}
