import 'package:belluga_now/infrastructure/services/push/push_answer_handler.dart';
import 'package:belluga_now/infrastructure/services/push/push_answer_resolver.dart';
import 'package:push_handler/push_handler.dart';

class PushAnswerRelay implements PushAnswerHandler, PushAnswerResolver {
  final Map<String, AnswerPayload> _answersByKey = {};

  @override
  Future<void> handle(AnswerPayload answer, StepData step) async {
    final key = _resolveStoreKey(step);
    if (key == null) {
      return;
    }
    _answersByKey[key] = answer;
  }

  @override
  Future<AnswerPayload?> resolve(StepData step) async {
    final key = _resolveStoreKey(step);
    if (key == null) {
      return null;
    }
    return _answersByKey[key];
  }

  void clear() {
    _answersByKey.clear();
  }

  String? _resolveStoreKey(StepData step) {
    final storeKey = step.onSubmit?.storeKey ?? step.config?.storeKey;
    if (storeKey == null || storeKey.isEmpty) {
      return null;
    }
    return storeKey;
  }
}
