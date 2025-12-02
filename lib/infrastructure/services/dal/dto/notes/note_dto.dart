class NoteDTO {
  String? id;
  String? courseItemId;
  String content;
  String? position;
  String? colorHex;

  NoteDTO(
      {required this.id,
      required this.courseItemId,
      required this.content,
      this.position,
      this.colorHex});

  factory NoteDTO.fromJson(Map<String, dynamic> json) {
    return NoteDTO(
      id: json['id'] as String,
      content: json['content'] as String,
      colorHex: json['color_hex'] as String?,
      position: json['position'] as String?,
      courseItemId: json['course_item_id'] as String,
    );
  }
}
