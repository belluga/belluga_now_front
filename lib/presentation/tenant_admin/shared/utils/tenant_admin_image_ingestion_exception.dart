class TenantAdminImageIngestionException implements Exception {
  TenantAdminImageIngestionException(this.message);

  final String message;

  @override
  String toString() => message;
}
