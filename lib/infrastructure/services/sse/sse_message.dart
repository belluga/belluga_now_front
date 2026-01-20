class SseMessage {
  SseMessage({
    required this.data,
    this.event,
    this.id,
  });

  final String data;
  final String? event;
  final String? id;
}
