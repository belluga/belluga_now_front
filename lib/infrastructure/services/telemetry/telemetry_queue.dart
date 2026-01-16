import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

class TelemetryQueue {
  TelemetryQueue({
    List<Duration>? retryDelays,
  }) : _retryDelays = retryDelays ??
            const [
              Duration.zero,
              Duration(seconds: 2),
              Duration(seconds: 4),
              Duration(seconds: 4),
            ];

  final List<Duration> _retryDelays;
  final Queue<_TelemetryJob> _jobs = Queue<_TelemetryJob>();
  bool _processing = false;

  Future<bool> enqueue(Future<void> Function() task) {
    final completer = Completer<bool>();
    _jobs.add(_TelemetryJob(task: task, completer: completer));
    _process();
    return completer.future;
  }

  Future<void> _process() async {
    if (_processing) return;
    _processing = true;

    while (_jobs.isNotEmpty) {
      final job = _jobs.removeFirst();
      var success = false;

      Object? lastError;
      StackTrace? lastStackTrace;
      for (final delay in _retryDelays) {
        if (delay > Duration.zero) {
          await Future<void>.delayed(delay);
        }
        try {
          await job.task();
          success = true;
          break;
        } catch (error, stackTrace) {
          lastError = error;
          lastStackTrace = stackTrace;
          success = false;
        }
      }

      if (!success && kIsWeb && lastError != null) {
        // ignore: avoid_print
        print(
          '[Telemetry][Web][Queue] job failed | $lastError\n$lastStackTrace',
        );
      }

      if (!job.completer.isCompleted) {
        job.completer.complete(success);
      }
    }

    _processing = false;
  }
}

class _TelemetryJob {
  _TelemetryJob({
    required this.task,
    required this.completer,
  });

  final Future<void> Function() task;
  final Completer<bool> completer;
}
