import 'package:belluga_now/application/router/support/route_redirect_path.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolveWebPromotionPath keeps invite context when code exists', () {
    final result = resolveWebPromotionPath(
      redirectPath: '/invite?code=ABCD1234',
    );

    expect(result, '/invite?code=ABCD1234');
  });

  test('resolveWebPromotionPath supports /convites alias when code exists', () {
    final result = resolveWebPromotionPath(
      redirectPath: '/convites?code=ABCD1234',
    );

    expect(result, '/invite?code=ABCD1234');
  });

  test('resolveWebPromotionPath ignores code outside invite context', () {
    final result = resolveWebPromotionPath(
      redirectPath: '/agenda/evento/evento-de-teste?code=ABCD1234',
    );

    expect(result, '/');
  });

  test('resolveWebPromotionPath falls back to home when code is missing', () {
    final result = resolveWebPromotionPath(
      redirectPath: '/invite',
    );

    expect(result, '/');
  });

  test('resolveWebPromotionPath falls back to home when path is empty', () {
    final result = resolveWebPromotionPath(redirectPath: '   ');

    expect(result, '/');
  });

  test('resolveWebPromotionShareCode returns code for invite context', () {
    final result = resolveWebPromotionShareCode(
      redirectPath: '/invite?code=ABCD1234',
    );

    expect(result, 'ABCD1234');
  });

  test('resolveWebPromotionShareCode returns null outside invite context', () {
    final result = resolveWebPromotionShareCode(
      redirectPath: '/descobrir?code=ABCD1234',
    );

    expect(result, isNull);
  });
}
