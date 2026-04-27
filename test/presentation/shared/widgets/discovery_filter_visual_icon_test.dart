import 'package:belluga_discovery_filters/belluga_discovery_filters.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:belluga_now/presentation/shared/widgets/discovery_filter_visual_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders canonical image visual when filter exposes imageUri', (
    tester,
  ) async {
    const item = DiscoveryFilterCatalogItem(
      key: 'show',
      label: 'Show',
      entities: <String>{'event'},
      imageUri: 'https://tenant.test/types/show.png',
      iconKey: 'place',
      colorHex: '#D81B60',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => buildDiscoveryFilterVisualIcon(
              context,
              item,
              true,
              Colors.white,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(BellugaNetworkImage), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('discoveryFilterVisualImage_show')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.place), findsNothing);
  });
}
