class InviteExternalContactShareTarget {
  const InviteExternalContactShareTarget({
    required this.id,
    required this.displayName,
    required this.primaryPhone,
    required this.primaryEmail,
  });

  final String id;
  final String displayName;
  final String? primaryPhone;
  final String? primaryEmail;

  bool get hasPhone => primaryPhone != null && primaryPhone!.trim().isNotEmpty;
  String get subtitle => hasPhone ? primaryPhone! : primaryEmail ?? '';
}
