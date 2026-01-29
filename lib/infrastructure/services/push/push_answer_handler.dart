import 'package:push_handler/push_handler.dart';

abstract class PushAnswerHandler {
  Future<void> handle(AnswerPayload answer, StepData step);
}
