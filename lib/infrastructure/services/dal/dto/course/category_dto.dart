class CategoryDTO {
  String id;
  String name;
  String slug;
  String? colorHex;

  CategoryDTO({required this.id, required this.name, required this.slug, this.colorHex});

  factory CategoryDTO.fromJson(Map<String, dynamic> json) {
    return CategoryDTO(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      colorHex: json['color_hex'] as String?,
    );
  }
}
