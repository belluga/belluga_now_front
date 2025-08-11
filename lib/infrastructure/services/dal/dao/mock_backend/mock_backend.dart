import 'package:belluga_now/infrastructure/services/dal/dao/auth_backend_contract.dart';
import 'package:belluga_now/infrastructure/services/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/services/dal/dao/mock_backend/mock_auth_backend.dart';
import 'package:belluga_now/infrastructure/services/dal/dao/mock_backend/mock_tenant_backend.dart';
import 'package:belluga_now/infrastructure/services/dal/dao/tenant_backend_contract.dart';

class MockBackend extends BackendContract {
  
  @override
  final AuthBackendContract auth = MockAuthBackend();

  @override
  final TenantBackendContract tenant = MockTenantBackend();
}
