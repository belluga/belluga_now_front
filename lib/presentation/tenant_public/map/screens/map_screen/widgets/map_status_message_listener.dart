import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_screen_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class MapStatusMessageListener extends StatefulWidget {
  const MapStatusMessageListener({
    super.key,
    required this.child,
    this.controller,
  });

  final Widget child;
  final MapScreenController? controller;

  @override
  State<MapStatusMessageListener> createState() =>
      _MapStatusMessageListenerState();
}

class _MapStatusMessageListenerState extends State<MapStatusMessageListener> {
  static const Duration _dedupeWindow = Duration(seconds: 2);

  late final MapScreenController _controller =
      widget.controller ?? GetIt.I.get<MapScreenController>();
  String? _lastShownMessage;
  DateTime? _lastShownAt;
  bool _snackBarScheduled = false;

  @override
  void initState() => super.initState();

  void _handleMessage(String? message) {
    if (message == null || message.isEmpty) {
      return;
    }
    if (_isDuplicate(message)) {
      _controller.clearStatusMessage();
      return;
    }
    if (_snackBarScheduled) {
      return;
    }
    _snackBarScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _snackBarScheduled = false;
      if (!mounted) return;
      if (_isDuplicate(message)) {
        _controller.clearStatusMessage();
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(message)),
        );
      _lastShownMessage = message;
      _lastShownAt = DateTime.now();
      _controller.clearStatusMessage();
    });
  }

  bool _isDuplicate(String message) {
    final lastShownAt = _lastShownAt;
    if (_lastShownMessage != message || lastShownAt == null) {
      return false;
    }
    return DateTime.now().difference(lastShownAt) <= _dedupeWindow;
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<String?>(
      streamValue: _controller.statusMessageStreamValue,
      builder: (context, statusMessage) {
        _handleMessage(statusMessage);
        return widget.child;
      },
    );
  }
}
