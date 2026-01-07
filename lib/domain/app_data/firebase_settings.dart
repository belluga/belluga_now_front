class FirebaseSettings {
  final String apiKey;
  final String appId;
  final String projectId;
  final String messagingSenderId;
  final String storageBucket;

  const FirebaseSettings({
    required this.apiKey,
    required this.appId,
    required this.projectId,
    required this.messagingSenderId,
    required this.storageBucket,
  });

  static FirebaseSettings? tryFromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final apiKey = map['apiKey'] as String?;
    final appId = map['appId'] as String?;
    final projectId = map['projectId'] as String?;
    final messagingSenderId = map['messagingSenderId'] as String?;
    final storageBucket = map['storageBucket'] as String?;

    if ([
      apiKey,
      appId,
      projectId,
      messagingSenderId,
      storageBucket,
    ].any((value) => value == null || value.isEmpty)) {
      return null;
    }

    return FirebaseSettings(
      apiKey: apiKey!,
      appId: appId!,
      projectId: projectId!,
      messagingSenderId: messagingSenderId!,
      storageBucket: storageBucket!,
    );
  }
}
