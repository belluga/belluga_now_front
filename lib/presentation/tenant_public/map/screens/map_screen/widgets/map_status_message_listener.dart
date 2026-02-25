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
  late final MapScreenController _controller =
      widget.controller ?? GetIt.I.get<MapScreenController>();

  @override
  void initState() => super.initState();

  void _handleMessage(String? message) {
    if (message == null || message.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      _controller.clearStatusMessage();
    });
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
