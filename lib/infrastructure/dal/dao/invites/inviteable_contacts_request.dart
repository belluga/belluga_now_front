class InviteableContactsRequest {
  const InviteableContactsRequest({
    required this.page,
    required this.pageSize,
  });

  final int page;
  final int pageSize;

  Map<String, dynamic> toQueryParameters() {
    return <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
  }
}
