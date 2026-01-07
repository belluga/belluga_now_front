import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:push_handler/push_handler.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  PushTransportConfig _buildTransportConfig() {
    return PushTransportConfig(
      baseUrl: 'https://example.com',
      tokenProvider: () async => 'token',
      deviceIdProvider: () async => 'device-id',
    );
  }

  Map<String, dynamic> _buildPayload({
    DateTime? expiresAt,
  }) {
    return {
      'ok': true,
      if (expiresAt != null) 'expires_at': expiresAt.toIso8601String(),
      'payload': {
        'title': 'Push Title',
        'body': 'Push body copy',
        'layoutType': 'fullScreen',
        'allowDismiss': true,
        'steps': [
          {
            'title': 'Step 1',
            'body': 'Step body',
          },
        ],
        'buttons': [],
      },
    };
  }

  testWidgets('auto-presents queued message on resume', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) {
            context = ctx;
            return const SizedBox();
          },
        ),
      ),
    );

    final queue = _FakePushBackgroundDeliveryQueue();
    await queue.save([
      PushDeliveryQueueItem(
        pushMessageId: 'msg-1',
        receivedAtIso: DateTime.now().toIso8601String(),
      ),
    ]);
    final client = _FakePushTransportClient(fetchResponse: _buildPayload());

    final repository = PushHandlerRepositoryDefault(
      transportConfig: _buildTransportConfig(),
      contextProvider: () => context,
      navigationResolver: null,
      onBackgroundMessage: (_) async {},
      transportClientOverride: client,
      deliveryQueueOverride: queue,
      enableFirebaseMessaging: false,
    );

    repository.flushBackgroundQueue();
    await tester.pumpAndSettle();

    expect(find.byType(PushScreenFull), findsOneWidget);

    final closeButton = find.byIcon(Icons.close);
    final skipButton = find.text('Pular');
    if (closeButton.evaluate().isNotEmpty) {
      await tester.tap(closeButton.first);
    } else {
      await tester.tap(skipButton.first);
    }
    await tester.pumpAndSettle();

    expect(find.byType(PushScreenFull), findsNothing);
    expect(queue.items, isEmpty);
    expect(
      client.actions.where((action) => action['action'] == 'opened').length,
      1,
    );
  });

  testWidgets('skips auto-present when expired', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) {
            context = ctx;
            return const SizedBox();
          },
        ),
      ),
    );

    final queue = _FakePushBackgroundDeliveryQueue();
    await queue.save([
      PushDeliveryQueueItem(
        pushMessageId: 'msg-2',
        receivedAtIso: DateTime.now().toIso8601String(),
      ),
    ]);
    final client = _FakePushTransportClient(
      fetchResponse: _buildPayload(
        expiresAt: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
    );

    final repository = PushHandlerRepositoryDefault(
      transportConfig: _buildTransportConfig(),
      contextProvider: () => context,
      navigationResolver: null,
      onBackgroundMessage: (_) async {},
      transportClientOverride: client,
      deliveryQueueOverride: queue,
      enableFirebaseMessaging: false,
    );

    await repository.flushBackgroundQueue();
    await tester.pumpAndSettle();

    expect(find.byType(PushScreenFull), findsNothing);
    expect(queue.items, isEmpty);
    expect(client.actions, isEmpty);
  });
}

class _FakePushTransportClient extends PushTransportClient {
  _FakePushTransportClient({
    required this.fetchResponse,
  }) : super(
          PushTransportConfig(
            baseUrl: 'https://example.com',
            tokenProvider: () async => 'token',
            deviceIdProvider: () async => 'device-id',
          ),
        );

  Map<String, dynamic>? fetchResponse;
  final List<Map<String, dynamic>> actions = [];

  @override
  Future<Map<String, dynamic>?> fetchMessagePayload({
    required String pushMessageId,
    String? tokenOverride,
  }) async {
    return fetchResponse;
  }

  @override
  Future<void> reportAction({
    required String pushMessageId,
    required String action,
    required int stepIndex,
    String? buttonKey,
    String? deviceId,
    Map<String, dynamic>? metadata,
    String? idempotencyKey,
    String? messageId,
    String? tokenOverride,
  }) async {
    actions.add({
      'push_message_id': pushMessageId,
      'action': action,
      'step_index': stepIndex,
    });
  }
}

class _FakePushBackgroundDeliveryQueue extends PushBackgroundDeliveryQueue {
  List<PushDeliveryQueueItem> items = [];

  @override
  Future<List<PushDeliveryQueueItem>> load() async => List.of(items);

  @override
  Future<void> save(List<PushDeliveryQueueItem> items) async {
    this.items = List.of(items);
  }

  @override
  Future<void> removeByIds(List<String> ids) async {
    if (ids.isEmpty) return;
    items = items.where((item) => !ids.contains(item.pushMessageId)).toList();
  }
}
