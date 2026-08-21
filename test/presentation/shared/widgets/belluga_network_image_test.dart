import 'dart:async';
import 'dart:io';

import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _ControlledImageTransport transport;

  setUp(() {
    transport = _ControlledImageTransport();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  tearDown(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  testWidgets(
    'retries a failed resized image once and keeps the placeholder pending',
    (tester) async {
      await _withControlledNetworkClient(transport, () async {
        const url = 'https://tenant.test/image.png';
        transport.enqueue(url, _ImageResponse.failure());
        final retrySuccess = _ImageResponse.success();
        transport.enqueue(url, retrySuccess);

        await tester.pumpWidget(
          _imageUnderTest(
            url: url,
            placeholder: const SizedBox(key: ValueKey<String>('placeholder')),
            errorWidget: const SizedBox(
              key: ValueKey<String>('final-fallback'),
            ),
          ),
        );
        await tester.pump();

        expect(
          find.byKey(const ValueKey<String>('placeholder')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('final-fallback')),
          findsNothing,
        );

        await tester.pumpAndSettle();
        await retrySuccess.completed;
        await _pumpUntilAbsent(
          tester,
          find.byKey(const ValueKey<String>('placeholder')),
        );
        expect(transport.requestCountFor(url), 2);
        expect(find.byKey(const ValueKey<String>('placeholder')), findsNothing);
        expect(
          find.byKey(const ValueKey<String>('final-fallback')),
          findsNothing,
        );
      });
    },
  );

  testWidgets('keeps the supplied fallback after the second failed request', (
    tester,
  ) async {
    await _withControlledNetworkClient(transport, () async {
      const url = 'https://tenant.test/unavailable.png';
      transport.enqueue(url, _ImageResponse.failure());
      transport.enqueue(url, _ImageResponse.failure());

      await tester.pumpWidget(
        _imageUnderTest(
          url: url,
          errorWidget: const SizedBox(key: ValueKey<String>('final-fallback')),
        ),
      );
      await tester.pumpAndSettle();

      expect(transport.requestCountFor(url), 2);
      expect(
        find.byKey(const ValueKey<String>('final-fallback')),
        findsOneWidget,
      );
    });
  });

  testWidgets('does not retry a successful first request', (tester) async {
    await _withControlledNetworkClient(transport, () async {
      const url = 'https://tenant.test/available.png';
      final success = _ImageResponse.success();
      transport.enqueue(url, success);

      await tester.pumpWidget(
        _imageUnderTest(
          url: url,
          placeholder: const SizedBox(key: ValueKey<String>('placeholder')),
          errorWidget: const SizedBox(key: ValueKey<String>('final-fallback')),
        ),
      );
      await _pumpUntilAbsent(
        tester,
        find.byKey(const ValueKey<String>('placeholder')),
      );

      expect(transport.requestCountFor(url), 1);
      expect(find.byKey(const ValueKey<String>('placeholder')), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('final-fallback')),
        findsNothing,
      );
    });
  });

}

Future<void> _pumpUntilAbsent(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    await tester.pump();
    if (finder.evaluate().isEmpty) {
      return;
    }
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
  fail(
    'Expected ${finder.describeMatch(Plurality.many)} to disappear after image load',
  );
}

Future<void> _withControlledNetworkClient(
  _ControlledImageTransport transport,
  Future<void> Function() body,
) async {
  debugNetworkImageHttpClientProvider = () => _ControlledHttpClient(transport);
  try {
    await body();
  } finally {
    debugNetworkImageHttpClientProvider = null;
  }
}

Widget _imageUnderTest({
  required String url,
  Widget? placeholder,
  Widget? errorWidget,
}) {
  return MaterialApp(
    home: Scaffold(
      body: BellugaNetworkImage(
        url,
        key: const ValueKey<String>('image'),
        cacheWidth: 40,
        cacheHeight: 40,
        placeholder: placeholder,
        errorWidget: errorWidget,
      ),
    ),
  );
}

class _ControlledHttpClient implements HttpClient {
  _ControlledHttpClient(this.transport);

  final _ControlledImageTransport transport;
  bool _autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async =>
      _ControlledHttpClientRequest(transport.next(url));

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _ControlledHttpClientRequest(transport.next(url));

  @override
  bool get autoUncompress => _autoUncompress;

  @override
  set autoUncompress(bool value) => _autoUncompress = value;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ControlledHttpClientRequest implements HttpClientRequest {
  _ControlledHttpClientRequest(this.response);

  final _ImageResponse response;

  @override
  Future<HttpClientResponse> close() => response.future;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ControlledImageTransport {
  final Map<String, List<_ImageResponse>> _responses =
      <String, List<_ImageResponse>>{};
  final Map<String, int> _requestCounts = <String, int>{};

  void enqueue(String url, _ImageResponse response) {
    _responses.putIfAbsent(url, () => <_ImageResponse>[]).add(response);
  }

  _ImageResponse next(Uri url) {
    final key = url.toString();
    _requestCounts[key] = requestCountFor(key) + 1;
    final responses = _responses[key];
    if (responses == null || responses.isEmpty) {
      throw StateError('Unexpected image request for $key');
    }
    return responses.removeAt(0);
  }

  int requestCountFor(String url) => _requestCounts[url] ?? 0;
}

class _ImageResponse extends Stream<List<int>> implements HttpClientResponse {
  _ImageResponse._(
    this.statusCode,
    this._stream,
    this._contentLength,
    this.completed,
  );

  factory _ImageResponse.failure() => _ImageResponse._(
    HttpStatus.internalServerError,
    Stream<List<int>>.empty(),
    0,
    Future<void>.value(),
  );

  factory _ImageResponse.success() {
    final controller = StreamController<List<int>>();
    controller.onListen = () {
      controller
        ..add(_transparentPng)
        ..close();
    };
    return _ImageResponse._(
      HttpStatus.ok,
      controller.stream,
      _transparentPng.length,
      controller.done,
    );
  }

  @override
  final int statusCode;
  final Stream<List<int>> _stream;
  final int _contentLength;
  final Future<void> completed;

  Future<HttpClientResponse> get future async => this;

  @override
  int get contentLength => _contentLength;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const List<int> _transparentPng = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];
