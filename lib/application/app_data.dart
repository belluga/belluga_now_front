class AppData {
  final String? port;
  final String hostname;
  final String href;

  AppData({required this.port, required this.hostname, required this.href});

  String get schema => href.split(hostname).first;
}
