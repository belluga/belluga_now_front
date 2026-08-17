import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_account_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps parent account publication status from payload to domain', () {
    final dto = TenantAdminAccountDTO.fromJson(<String, dynamic>{
      'id': 'acc-1',
      'name': 'Conta teste',
      'slug': 'conta-teste',
      'document': <String, dynamic>{'type': 'cpf', 'number': '000'},
      'ownership_state': 'tenant_owned',
      'publication': <String, dynamic>{'status': 'published'},
    });

    final account = dto.toDomain();

    expect(account.publication.status.value, 'published');
  });
}
