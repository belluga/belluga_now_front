import 'package:lint_matrix_fixture/infrastructure/dal/dto/fake_dto.dart';

class _MappedDomainModel {
  const _MappedDomainModel();
}

class RepositoryInlineMapperCase {
  // expect_lint: repository_inline_dto_to_domain_mapper_forbidden
  _MappedDomainModel mapFakeDto(FakeDto dto) => const _MappedDomainModel();

  void forward(FakeDto dto) {
    dto.hashCode;
  }
}

// expect_lint: repository_inline_dto_to_domain_mapper_forbidden
_MappedDomainModel mapFakeDtoTopLevel(FakeDto dto) => const _MappedDomainModel();
