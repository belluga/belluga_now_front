import 'package:belluga_now/infrastructure/services/push/push_gatekeeper.dart';
import 'package:belluga_now/infrastructure/services/push/push_answer_resolver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_handler/push_handler.dart';

void main() {
  test('selection_min gate checks answers via resolver', () async {
    final resolver = _FakeAnswerResolver();
    final gatekeeper = PushGatekeeper(
      contextProvider: () => null,
      answerResolver: resolver,
    );
    final step = StepData.fromMap({
      'slug': 'select-tags',
      'type': 'selector',
      'title': 'Select',
      'gate': {
        'type': 'selection_min',
        'min_selected': 2,
      },
      'config': {
        'selection_ui': 'inline',
        'selection_mode': 'multi',
        'layout': 'list',
        'min_selected': 2,
        'store_key': 'preferences.tags',
        'options': [
          {'id': 'a', 'label': 'Option A'},
          {'id': 'b', 'label': 'Option B'},
        ],
      },
      'buttons': [],
    });

    final initialAllowed = await gatekeeper.check(step);
    expect(initialAllowed, isFalse);

    final answer = AnswerPayload(
      stepSlug: 'select-tags',
      value: ['a', 'b'],
      metadata: const {},
    );
    resolver.setAnswer(answer);

    final allowed = await gatekeeper.check(step);
    expect(allowed, isTrue);
  });
}

class _FakeAnswerResolver implements PushAnswerResolver {
  AnswerPayload? _answer;

  void setAnswer(AnswerPayload answer) {
    _answer = answer;
  }

  @override
  Future<AnswerPayload?> resolve(StepData step) async {
    return _answer;
  }
}
