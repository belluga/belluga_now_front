class DeferredLinkNativePayload {
  const DeferredLinkNativePayload({this.resolverPayload, this.storeChannel});

  final String? resolverPayload;
  final String? storeChannel;

  bool get hasAnyValue =>
      (resolverPayload != null && resolverPayload!.trim().isNotEmpty) ||
      (storeChannel != null && storeChannel!.trim().isNotEmpty);
}
