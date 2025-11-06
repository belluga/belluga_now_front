class InviteFriendModel {
  const InviteFriendModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.matchLabel,
  });

  final String id;
  final String name;
  final String avatarUrl;
  final String matchLabel;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! InviteFriendModel) {
      return false;
    }
    return other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
