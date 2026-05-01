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

  test('resolveWebPromotionPath preserves event detail occurrence intent', () {
    final result = resolveWebPromotionPath(
      redirectPath: '/agenda/evento/evento-de-teste?occurrence=occ-1',
    );

    expect(result, '/agenda/evento/evento-de-teste?occurrence=occ-1');
  });

  test('resolveWebPromotionPath strips non-route query from event detail', () {
    final result = resolveWebPromotionPath(
      redirectPath: '/agenda/evento/evento-de-teste?code=ABCD1234',
    );

    expect(result, '/agenda/evento/evento-de-teste');
  });

  test('resolveWebPromotionPath preserves invite entry when code is missing',
      () {
    final result = resolveWebPromotionPath(
      redirectPath: '/invite',
    );

    expect(result, '/invite');
  });

  test('resolveWebPromotionPath falls back to home when path is empty', () {
    final result = resolveWebPromotionPath(redirectPath: '   ');

    expect(result, '/');
  });

  test('resolveWebPromotionPath falls back for blocked non-detail agenda path',
      () {
    final result = resolveWebPromotionPath(redirectPath: '/agenda');

    expect(result, '/');
  });

  test('resolveWebPromotionPath falls back for external absolute URL', () {
    final result = resolveWebPromotionPath(
      redirectPath: 'https://evil.example/agenda/evento/show-1',
    );

    expect(result, '/');
  });

  test('resolveWebPromotionPath falls back for external invite URL', () {
    final result = resolveWebPromotionPath(
      redirectPath: 'https://evil.example/invite?code=ABCD1234',
    );

    expect(result, '/');
  });

  test('resolveWebPromotionPath falls back for scheme-relative URL', () {
    final result = resolveWebPromotionPath(
      redirectPath: '//evil.example/agenda/evento/show-1',
    );

    expect(result, '/');
  });

  test('resolveWebPromotionPath falls back for scheme-relative invite URL', () {
    final result = resolveWebPromotionPath(
      redirectPath: '//evil.example/invite?code=ABCD1234',
    );

    expect(result, '/');
  });

  test('resolveWebPromotionDismissPath falls back to home for auth-owned paths',
      () {
    final result = resolveWebPromotionDismissPath(
      redirectPath: '/profile',
    );

    expect(result, '/');
  });

  test(
      'resolveWebPromotionDismissPath preserves invite preview redirect when code exists',
      () {
    final result = resolveWebPromotionDismissPath(
      redirectPath: '/invite?code=ABCD1234',
    );

    expect(result, '/invite?code=ABCD1234');
  });

  test('resolveWebPromotionDismissPath preserves public detail redirect', () {
    final result = resolveWebPromotionDismissPath(
      redirectPath: '/parceiro/casa-marracini',
    );

    expect(result, '/parceiro/casa-marracini');
  });

  test('resolveWebPromotionPath preserves map poi query intent', () {
    final result = resolveWebPromotionPath(
      redirectPath: '/mapa/poi?poi=event:evt-1&stack=stack-1&extra=ignored',
    );

    expect(result, '/mapa/poi?poi=event%3Aevt-1&stack=stack-1');
  });

  test('resolveWebPromotionShareCode returns code for invite context', () {
    final result = resolveWebPromotionShareCode(
      redirectPath: '/invite?code=ABCD1234',
    );

    expect(result, 'ABCD1234');
  });

  test('resolveWebPromotionShareCode rejects external invite context', () {
    final result = resolveWebPromotionShareCode(
      redirectPath: 'https://evil.example/invite?code=ABCD1234',
    );

    expect(result, isNull);
  });

  test('resolveWebPromotionShareCode returns null outside invite context', () {
    final result = resolveWebPromotionShareCode(
      redirectPath: '/descobrir?code=ABCD1234',
    );

    expect(result, isNull);
  });

  test('buildWebPromotionBoundaryPath preserves redirect path in query', () {
    final result = buildWebPromotionBoundaryPath(
      redirectPath: '/profile?tab=settings',
    );

    expect(
      result,
      '/baixe-o-app?redirect=%2Fprofile%3Ftab%3Dsettings',
    );
  });

  test('resolveWebPromotionPath falls back for over-nested auth redirect', () {
    final result = resolveWebPromotionPath(
      redirectPath: _nestedAuthRedirect(depth: 8, terminal: '/descobrir'),
    );

    expect(result, '/');
  });

  test('isAuthOwnedPromotionRedirectPath matches auth-owned redirect family',
      () {
    expect(isAuthOwnedPromotionRedirectPath('/profile'), isTrue);
    expect(isAuthOwnedPromotionRedirectPath('/workspace/tenant-a'), isTrue);
    expect(isAuthOwnedPromotionRedirectPath('/auth/login'), isTrue);
    expect(isAuthOwnedPromotionRedirectPath('/convites/compartilhar'), isTrue);
    expect(isAuthOwnedPromotionRedirectPath('/agenda/evento/show-1'), isFalse);
  });
}

String _nestedAuthRedirect({
  required int depth,
  required String terminal,
}) {
  var value = terminal;
  for (var index = 0; index < depth; index += 1) {
    value = Uri(
      path: '/auth/login',
      queryParameters: <String, String>{'redirect': value},
    ).toString();
  }
  return value;
}
