import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> expectStickyDateHeaderTransitions({
  required WidgetTester tester,
  required Finder scrollable,
  required Finder pinnedChrome,
  required List<String> dateLabels,
  bool verifyPrePinEntry = true,
}) async {
  expect(dateLabels, hasLength(4));
  final scrollableOwner = find
      .descendant(of: scrollable, matching: find.byType(Scrollable))
      .first;
  if (verifyPrePinEntry) {
    final firstHeader = find.text(dateLabels[0]);
    final chromeBottom = tester.getBottomLeft(pinnedChrome).dy;
    final initialHeaderTop = tester.getTopLeft(firstHeader).dy;
    expect(initialHeaderTop, greaterThan(chromeBottom));

    await tester.drag(scrollableOwner, const Offset(0, -24));
    await tester.pump();

    expect(
      tester.getTopLeft(firstHeader).dy,
      lessThan(initialHeaderTop),
      reason:
          'The first date header must move upward before it becomes pinned.',
    );
  }

  final firstPinnedTop = await _pinHeader(
    tester: tester,
    scrollable: scrollableOwner,
    label: dateLabels[0],
  );
  _expectOnlyHeaderAtPinnedBoundary(
    tester: tester,
    dateLabels: dateLabels,
    expectedLabel: dateLabels[0],
    pinnedTop: firstPinnedTop,
    pinnedChrome: pinnedChrome,
  );
  await _pushHeader(
    tester: tester,
    scrollable: scrollableOwner,
    previousLabel: dateLabels[0],
    nextLabel: dateLabels[1],
    pinnedTop: firstPinnedTop,
  );
  _expectOnlyHeaderAtPinnedBoundary(
    tester: tester,
    dateLabels: dateLabels,
    expectedLabel: dateLabels[1],
    pinnedTop: firstPinnedTop,
    pinnedChrome: pinnedChrome,
  );
  await _pushHeader(
    tester: tester,
    scrollable: scrollableOwner,
    previousLabel: dateLabels[1],
    nextLabel: dateLabels[2],
    pinnedTop: firstPinnedTop,
  );
  _expectOnlyHeaderAtPinnedBoundary(
    tester: tester,
    dateLabels: dateLabels,
    expectedLabel: dateLabels[2],
    pinnedTop: firstPinnedTop,
    pinnedChrome: pinnedChrome,
  );
  await _pushHeader(
    tester: tester,
    scrollable: scrollableOwner,
    previousLabel: dateLabels[2],
    nextLabel: dateLabels[3],
    pinnedTop: firstPinnedTop,
  );
  _expectOnlyHeaderAtPinnedBoundary(
    tester: tester,
    dateLabels: dateLabels,
    expectedLabel: dateLabels[3],
    pinnedTop: firstPinnedTop,
    pinnedChrome: pinnedChrome,
  );

  await _returnToPreviousHeader(
    tester: tester,
    scrollable: scrollableOwner,
    previousLabel: dateLabels[2],
    currentLabel: dateLabels[3],
    pinnedTop: firstPinnedTop,
  );
  _expectOnlyHeaderAtPinnedBoundary(
    tester: tester,
    dateLabels: dateLabels,
    expectedLabel: dateLabels[2],
    pinnedTop: firstPinnedTop,
    pinnedChrome: pinnedChrome,
  );
}

void _expectOnlyHeaderAtPinnedBoundary({
  required WidgetTester tester,
  required List<String> dateLabels,
  required String expectedLabel,
  required double pinnedTop,
  required Finder pinnedChrome,
}) {
  final chromeBottom = tester.getBottomLeft(pinnedChrome).dy;
  final pinnedHeaderSurface = _dateHeaderSurface(expectedLabel);
  expect(
    tester.getTopLeft(pinnedHeaderSurface).dy,
    closeTo(chromeBottom, 2),
    reason: 'The date boundary must follow the last production pinned chrome.',
  );
  final headersAtBoundary = <String>[];
  for (final label in dateLabels) {
    final header = find.text(label);
    if (header.evaluate().isNotEmpty &&
        (tester.getTopLeft(_dateHeaderSurface(label)).dy - chromeBottom)
                .abs() <=
            2) {
      headersAtBoundary.add(label);
    }
  }

  expect(headersAtBoundary, [
    expectedLabel,
  ], reason: 'Exactly one date header must own the pinned boundary.');
}

Finder _dateHeaderSurface(String label) {
  return find
      .ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is ColoredBox &&
              widget.child is Padding &&
              (widget.child as Padding).padding ==
                  const EdgeInsets.symmetric(vertical: 20),
        ),
      )
      .first;
}

Future<void> _returnToPreviousHeader({
  required WidgetTester tester,
  required Finder scrollable,
  required String previousLabel,
  required String currentLabel,
  required double pinnedTop,
}) async {
  final previousHeader = find.text(previousLabel);
  final currentHeader = find.text(currentLabel);
  for (var attempt = 0; attempt < 30; attempt++) {
    if (previousHeader.evaluate().isNotEmpty &&
        currentHeader.evaluate().isNotEmpty &&
        tester.getTopLeft(previousHeader).dy >= pinnedTop - 2 &&
        tester.getTopLeft(currentHeader).dy > pinnedTop + 8) {
      break;
    }
    await tester.drag(scrollable, const Offset(0, 40));
    await tester.pump();
  }
  expect(tester.getTopLeft(previousHeader).dy, closeTo(pinnedTop, 2));
  expect(tester.getTopLeft(currentHeader).dy, greaterThan(pinnedTop + 8));
}

Future<double> _pinHeader({
  required WidgetTester tester,
  required Finder scrollable,
  required String label,
}) async {
  final header = find.text(label);
  await tester.scrollUntilVisible(header, 80, scrollable: scrollable);

  double? previousTop;
  for (var attempt = 0; attempt < 30; attempt++) {
    final top = tester.getTopLeft(header).dy;
    if (previousTop != null && (top - previousTop).abs() < 1) {
      return top;
    }
    previousTop = top;
    await tester.drag(scrollable, const Offset(0, -40));
    await tester.pump();
  }
  fail('Date header "$label" never reached its pinned position.');
}

Future<void> _pushHeader({
  required WidgetTester tester,
  required Finder scrollable,
  required String previousLabel,
  required String nextLabel,
  required double pinnedTop,
}) async {
  final previousHeader = find.text(previousLabel);
  final nextHeader = find.text(nextLabel);
  await tester.scrollUntilVisible(nextHeader, 80, scrollable: scrollable);

  for (var attempt = 0; attempt < 40; attempt++) {
    if (tester.getTopLeft(nextHeader).dy <= pinnedTop + 1) {
      break;
    }
    await tester.drag(scrollable, const Offset(0, -30));
    await tester.pump();
  }

  expect(tester.getTopLeft(nextHeader).dy, closeTo(pinnedTop, 2));
  if (previousHeader.evaluate().isNotEmpty) {
    expect(
      tester.getBottomLeft(previousHeader).dy,
      lessThanOrEqualTo(tester.getTopLeft(nextHeader).dy + 2),
    );
  }
}
