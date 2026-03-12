import 'package:belluga_custom_lint/src/path_utils.dart';
import 'package:test/test.dart';

void main() {
  group('isGeneratedFilePath', () {
    test('matches known generated suffixes', () {
      expect(isGeneratedFilePath('lib/foo/bar.g.dart'), isTrue);
      expect(isGeneratedFilePath('lib/foo/bar.freezed.dart'), isTrue);
      expect(isGeneratedFilePath('lib/foo/bar.gr.dart'), isTrue);
      expect(isGeneratedFilePath('lib/foo/bar.mocks.dart'), isTrue);
    });

    test('ignores normal source files', () {
      expect(isGeneratedFilePath('lib/foo/bar.dart'), isFalse);
    });
  });

  group('domain scope helpers', () {
    test('detects domain value object files', () {
      expect(
        isDomainValueObjectFilePath(
          '/workspace/flutter-app/lib/domain/user/value_objects/user_id_value.dart',
        ),
        isTrue,
      );
    });

    test('detects non value object domain files', () {
      expect(
        isDomainValueObjectFilePath(
          '/workspace/flutter-app/lib/domain/user/user_profile.dart',
        ),
        isFalse,
      );
    });
  });

  group('presentationRootKey', () {
    test('resolves feature root from absolute file path', () {
      final root = presentationRootKey(
        '/workspace/flutter-app/lib/presentation/tenant_public/home/screens/home_screen.dart',
      );

      expect(root, 'tenant_public/home');
    });

    test('resolves feature root from package URI path', () {
      final root = presentationRootKey(
        'package:lint_matrix_fixture/presentation/tenant_public/map/controllers/map_controller.dart',
      );

      expect(root, 'tenant_public/map');
    });

    test('resolves feature root from generic URI-like path', () {
      final root = presentationRootKey(
        'asset:lint_matrix_fixture/lib/presentation/tenant_public/schedule/controllers/schedule_controller.dart',
      );

      expect(root, 'tenant_public/schedule');
    });
  });

  group('infrastructure scope helpers', () {
    test('detects repository files', () {
      expect(
        isRepositoryFilePath(
          '/workspace/flutter-app/lib/infrastructure/repositories/auth_repository.dart',
        ),
        isTrue,
      );
    });

    test('detects service files', () {
      expect(
        isServiceFilePath(
          '/workspace/flutter-app/lib/infrastructure/services/http/client.dart',
        ),
        isTrue,
      );
    });

    test('detects dto mapper files', () {
      expect(
        isDtoMapperFilePath(
          '/workspace/flutter-app/lib/infrastructure/dal/dto/mappers/user_dto_mapper.dart',
        ),
        isTrue,
      );
    });
  });
}
