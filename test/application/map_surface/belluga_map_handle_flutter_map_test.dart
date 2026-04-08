import 'package:belluga_now/application/map_surface/belluga_map_handle_flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('upper viewport anchor produces negative move offset', () {
    final offset = BellugaMapHandle.calculateAnchoredMoveOffset(
      viewportHeight: 1000,
      verticalViewportAnchor: 0.28,
    );

    expect(offset.dx, closeTo(0, 1e-9));
    expect(offset.dy, closeTo(-220, 1e-9));
  });

  test('lower viewport anchor produces positive move offset', () {
    final offset = BellugaMapHandle.calculateAnchoredMoveOffset(
      viewportHeight: 1000,
      verticalViewportAnchor: 0.72,
    );

    expect(offset.dx, closeTo(0, 1e-9));
    expect(offset.dy, closeTo(220, 1e-9));
  });
}
