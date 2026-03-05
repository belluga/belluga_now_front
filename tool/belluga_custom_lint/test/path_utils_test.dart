import 'package:belluga_custom_lint/src/path_utils.dart';
import 'package:test/test.dart';

void main() {
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
  });
}
