// ignore_for_file: unused_element

class _FakeDomain {
  const _FakeDomain();
}

class _FakeDto {
  const _FakeDto();

  _FakeDomain toDomain() => const _FakeDomain();
}

mixin _BadMapperCase {
  // expect_lint: dto_mapper_pass_through_forbidden
  _FakeDomain mapFakeDto(_FakeDto dto) => dto.toDomain();

  // expect_lint: dto_mapper_pass_through_forbidden
  _FakeDomain mapFakeDtoBlock(_FakeDto dto) {
    return dto.toDomain();
  }

  // expect_lint: dto_mapper_pass_through_forbidden
  _FakeDomain mapFromPrimitive(String raw) {
    if (raw.isEmpty) {
      return const _FakeDomain();
    }
    return const _FakeDomain();
  }
}

mixin _GoodMapperCase {
  _FakeDto parseFromPrimitive(String raw) {
    if (raw.isEmpty) {
      return const _FakeDto();
    }
    return const _FakeDto();
  }

  void touch(_FakeDto dto) {
    dto.hashCode;
  }
}
