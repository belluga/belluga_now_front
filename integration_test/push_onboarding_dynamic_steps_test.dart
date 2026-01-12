import 'dart:async';

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

  Map<String, dynamic> _buildPayload() {
    return {
      'ok': true,
      'payload': {
        'title': 'Onboarding',
        'body': 'Start here',
        'layoutType': 'fullScreen',
        'closeBehavior': 'after_action',
        'steps': [
          {
            'slug': 'choose-one',
            'type': 'selector',
            'title': 'Pick one',
            'body': 'Select your favorite',
            'onSubmit': {
              'action': 'save_response',
              'store_key': 'preferences.favorite',
            },
            'config': {
              'selection_ui': 'inline',
              'selection_mode': 'single',
              'layout': 'list',
              'options': [
                {'id': 'a', 'label': 'Option A'},
                {'id': 'b', 'label': 'Option B'},
              ],
            },
          },
          {
            'slug': 'dynamic-options',
            'type': 'selector',
            'title': 'Select items',
            'body': 'Choose as many as you want',
            'config': {
              'selection_ui': 'inline',
              'selection_mode': 'multi',
              'layout': 'tags',
              'option_source': {
                'type': 'method',
                'name': 'getTags',
                'params': {'include': ['beaches', 'food']},
              },
            },
          },
        ],
        'buttons': [],
      },
    };
  }

  Map<String, dynamic> _buildGatePayload({
    required bool gateFirst,
  }) {
    final steps = <Map<String, dynamic>>[
      {
        'slug': 'intro',
        'type': 'cta',
        'title': 'Intro',
        'body': 'Welcome',
      },
      {
        'slug': 'gate-step',
        'type': 'cta',
        'title': 'Gate Step',
        'body': 'Needs permission',
        'gate': {
          'type': 'location_permission',
        },
      },
      {
        'slug': 'after',
        'type': 'cta',
        'title': 'After Gate',
        'body': 'Continue flow',
      },
    ];

    return {
      'ok': true,
      'payload': {
        'title': 'Gate Flow',
        'body': 'Test gate skip',
        'layoutType': 'fullScreen',
        'closeBehavior': 'after_action',
        'steps': gateFirst
            ? [steps[1], steps[2]]
            : [steps[0], steps[1], steps[2]],
        'buttons': [],
      },
    };
  }

  testWidgets('renders dynamic onboarding steps via debug injection',
      (tester) async {
    late BuildContext context;
    AnswerPayload? submitted;

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

    final client = _FakePushTransportClient(fetchResponse: _buildPayload());
    final repository = PushHandlerRepositoryDefault(
      transportConfig: _buildTransportConfig(),
      contextProvider: () => context,
      navigationResolver: null,
      onBackgroundMessage: (_) async {},
      transportClientOverride: client,
      enableFirebaseMessaging: false,
      gatekeeper: (_) async => true,
      optionsBuilder: (_) async => const [
        OptionItem(value: 'dynamic', label: 'Dynamic Option'),
      ],
      onStepSubmit: (answer, _) async {
        submitted = answer;
      },
    );

    await repository.init();
    addTearDown(repository.dispose);
    unawaited(repository.debugInjectMessageId('msg-1'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Pick one'), findsOneWidget);
    await tester.tap(find.text('Option A'));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Continuar'));
    await tester.pump(const Duration(seconds: 1));

    expect(submitted?.stepSlug, 'choose-one');
    expect(submitted?.value, 'a');
    expect(find.text('Select items'), findsOneWidget);
    expect(find.text('Dynamic Option'), findsOneWidget);
  });

  testWidgets('skips pre-approved gate before initial render',
      (tester) async {
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

    final client =
        _FakePushTransportClient(fetchResponse: _buildGatePayload(gateFirst: true));
    final repository = PushHandlerRepositoryDefault(
      transportConfig: _buildTransportConfig(),
      contextProvider: () => context,
      navigationResolver: null,
      onBackgroundMessage: (_) async {},
      transportClientOverride: client,
      enableFirebaseMessaging: false,
      gatekeeper: (step) async => step.slug == 'gate-step',
    );

    await repository.init();
    addTearDown(repository.dispose);

    unawaited(repository.debugInjectMessageId('msg-2'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Gate Step'), findsNothing);
    expect(find.text('After Gate'), findsOneWidget);
  });

  testWidgets('back button skips already-passed gate', (tester) async {
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

    final client =
        _FakePushTransportClient(fetchResponse: _buildGatePayload(gateFirst: false));
    final repository = PushHandlerRepositoryDefault(
      transportConfig: _buildTransportConfig(),
      contextProvider: () => context,
      navigationResolver: null,
      onBackgroundMessage: (_) async {},
      transportClientOverride: client,
      enableFirebaseMessaging: false,
      gatekeeper: (step) async => step.slug == 'gate-step',
    );

    await repository.init();
    addTearDown(repository.dispose);

    unawaited(repository.debugInjectMessageId('msg-3'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Intro'), findsOneWidget);
    await tester.tap(find.text('Continuar'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('After Gate'), findsOneWidget);
    await tester.tap(find.text('voltar'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Intro'), findsOneWidget);
    expect(find.text('Gate Step'), findsNothing);
  });

  testWidgets('system back behaves like voltar', (tester) async {
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

    final client = _FakePushTransportClient(fetchResponse: {
      'ok': true,
      'payload': {
        'title': 'Back Flow',
        'body': 'Test system back',
        'layoutType': 'fullScreen',
        'closeBehavior': 'after_action',
        'steps': [
          {
            'slug': 'step-1',
            'type': 'cta',
            'title': 'Step One',
            'body': 'First',
          },
          {
            'slug': 'step-2',
            'type': 'cta',
            'title': 'Step Two',
            'body': 'Second',
          },
        ],
        'buttons': [],
      },
    });

    final repository = PushHandlerRepositoryDefault(
      transportConfig: _buildTransportConfig(),
      contextProvider: () => context,
      navigationResolver: null,
      onBackgroundMessage: (_) async {},
      transportClientOverride: client,
      enableFirebaseMessaging: false,
    );

    await repository.init();
    addTearDown(repository.dispose);

    unawaited(repository.debugInjectMessageId('msg-4'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Step One'), findsOneWidget);

    await tester.tap(find.text('Continuar'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Step Two'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Step One'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Step One'), findsOneWidget);
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

  @override
  Future<Map<String, dynamic>?> fetchMessagePayload({
    required String pushMessageId,
    String? tokenOverride,
  }) async {
    return fetchResponse;
  }
}
