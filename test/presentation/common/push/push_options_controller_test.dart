import 'package:belluga_now/presentation/shared/push/controllers/push_options_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_handler/push_handler.dart';

void main() {
  test('returns static favorites for getFavorites method', () async {
    final controller = PushOptionsController();

    final items = await controller.resolve(
      const OptionSource(
        type: 'method',
        name: 'getFavorites',
        params: {},
      ),
    );

    expect(items, isNotEmpty);
    expect(items.first.value, isNotNull);
    expect(items.first.label, isNotNull);
  });

  test('returns static tags for getTags method', () async {
    final controller = PushOptionsController();

    final items = await controller.resolve(
      const OptionSource(
        type: 'method',
        name: 'getTags',
        params: {},
      ),
    );

    expect(items, isNotEmpty);
    expect(items.map((item) => item.value), contains('praias'));
  });

  test('returns empty list for unknown source type', () async {
    final controller = PushOptionsController();

    final items = await controller.resolve(
      const OptionSource(
        type: 'query',
        name: 'getTags',
        params: {},
      ),
    );

    expect(items, isEmpty);
  });
}
