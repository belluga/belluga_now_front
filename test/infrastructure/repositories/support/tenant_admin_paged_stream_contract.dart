import 'package:flutter_test/flutter_test.dart';

typedef LoadPage = Future<void> Function();
typedef ResetState = void Function();
typedef ReadItems<T> = List<T>? Function();
typedef ReadHasMore = bool Function();
typedef ReadError = String? Function();

Future<void> verifyTenantAdminPagedStreamContract<T>({
  required String scope,
  required LoadPage loadFirstPage,
  required LoadPage loadNextPage,
  required ResetState resetState,
  required ReadItems<T> readItems,
  required ReadHasMore readHasMore,
  required ReadError readError,
  required List<int> expectedCountsPerStep,
  int loadNextCalls = 0,
}) async {
  expect(
    expectedCountsPerStep.isNotEmpty,
    isTrue,
    reason: '$scope must provide at least one expected count step.',
  );

  await loadFirstPage();
  expect(readItems()?.length, expectedCountsPerStep.first);
  expect(readError(), isNull);

  for (var index = 0; index < loadNextCalls; index++) {
    await loadNextPage();
    expect(readItems()?.length, expectedCountsPerStep[index + 1]);
  }

  resetState();
  expect(readItems(), isNull);
  expect(readError(), isNull);
  expect(readHasMore(), isTrue);
}
