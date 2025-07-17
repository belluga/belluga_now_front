class NoteDTO {
  String id;
  String? title;
  String content;
  String? colorHex;

  NoteDTO({required this.id, required this.content, this.title, this.colorHex});

  factory NoteDTO.fromJson(Map<String, dynamic> json) {
    return NoteDTO(
      id: json['id'] as String,
      title: json['title'] as String?,
      content: json['content'] as String,
      colorHex: json['color_hex'] as String?,
    );
  }
}
