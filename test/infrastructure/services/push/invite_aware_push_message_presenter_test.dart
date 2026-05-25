import 'package:belluga_now/infrastructure/services/push/invite_aware_push_message_presenter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_handler/push_handler.dart';

void main() {
  group('InviteAwarePushMessagePresenter', () {
    final presenter = InviteAwarePushMessagePresenter();

    test('skips generic presentation for invite received copy', () {
      final message = _buildMessageData(
        title: 'Convite para Festival Belluga',
      );

      expect(presenter.shouldSkipGenericPresentation(message), isTrue);
    });

    test('skips generic presentation for invite accepted copy', () {
      final message = _buildMessageData(
        title: 'Seu convite foi aceito',
      );

      expect(presenter.shouldSkipGenericPresentation(message), isTrue);
    });

    test('does not skip generic presentation for non-invite simple copy', () {
      final message = _buildMessageData(
        title: 'Atualizacao do sistema',
        body: 'Abra o app para ver os detalhes.',
      );

      expect(presenter.shouldSkipGenericPresentation(message), isFalse);
    });

    testWidgets(
        'shows visible invite-specific foreground signal for accepted copy',
        (tester) async {
      BuildContext? capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                capturedContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      final presenter = InviteAwarePushMessagePresenter(
        contextProvider: () => capturedContext,
      );

      await presenter.present(
        messageData: _buildMessageData(title: 'Seu convite foi aceito'),
        reportAction: ({
          required String action,
          required int stepIndex,
          required StepData step,
          String? buttonKey,
          ButtonData? button,
          String? deviceId,
        }) async {},
      );
      await tester.pump();

      expect(find.text('Seu convite foi aceito'), findsOneWidget);
    });
  });
}

MessageData _buildMessageData({
  required String title,
  String body = 'Abra o app para ver os detalhes do convite.',
}) {
  return MessageData.fromMap({
    'title': title,
    'body': body,
    'layoutType': 'bottomModal',
    'closeBehavior': 'after_action',
    'steps': const <Map<String, dynamic>>[],
    'buttons': const <Map<String, dynamic>>[],
  });
}
