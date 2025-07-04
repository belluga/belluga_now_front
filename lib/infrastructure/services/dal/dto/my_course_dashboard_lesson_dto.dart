class MyCourseDashboardLessonDto {
  final String id;
  final String title;
  final String description;
  final String thumbUrl;

  MyCourseDashboardLessonDto({required this.id,required this.title, required this.description,required this.thumbUrl});

  factory MyCourseDashboardLessonDto.fromJson(Map<String, Object?> map) {
    final _id = map['id'] as String;
    final _thumb = map['thumb_url'] as String;
    final _title = map['title'] as String;
    final _description = map['description'] as String;

    return MyCourseDashboardLessonDto(
      id: _id,
      title: _title,
      description: _description,
      thumbUrl: _thumb,
    );
  }
    
  
}