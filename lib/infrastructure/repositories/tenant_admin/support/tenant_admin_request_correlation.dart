import 'package:uuid/uuid.dart';

class TenantAdminRequestCorrelation {
  TenantAdminRequestCorrelation._(this.id);

  factory TenantAdminRequestCorrelation.create() =>
      TenantAdminRequestCorrelation._(const Uuid().v4());

  final String id;

  Map<String, String> headers() => {'X-Request-Id': id};
}
