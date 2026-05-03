class InviteContactImportItemRequest {
  const InviteContactImportItemRequest({
    required this.type,
    required this.hash,
  });

  final String type;
  final String hash;

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'hash': hash,
    };
  }
}
