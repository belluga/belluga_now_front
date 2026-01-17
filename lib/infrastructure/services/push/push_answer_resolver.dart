import 'package:push_handler/push_handler.dart';

abstract class PushAnswerResolver {
  Future<AnswerPayload?> resolve(StepData step);
}
