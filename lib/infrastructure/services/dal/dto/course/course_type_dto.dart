class CourseTypeDTO {
  String id;
  String name;
  String slug;

  CourseTypeDTO({required this.id, required this.name, required this.slug});

  factory CourseTypeDTO.fromJson(Map<String, dynamic> json) {
    return CourseTypeDTO(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'slug': slug};
  }
}
