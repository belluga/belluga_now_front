// expect_lint: domain_dto_dependency_forbidden
import 'package:lint_matrix_fixture/infrastructure/dal/dto/fake_dto.dart';

class DomainCase {
  const DomainCase();

  FakeDto build() => const FakeDto();
}
