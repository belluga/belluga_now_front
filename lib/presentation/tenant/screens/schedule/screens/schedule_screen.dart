import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/tenant/screens/schedule/controller/schedule_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/screens/schedule/widgets/dates_row.dart';
import 'package:belluga_now/presentation/tenant/screens/schedule/widgets/event_card.dart';
import 'package:belluga_now/presentation/tenant/widgets/back_button_belluga.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _controller = GetIt.I.get<ScheduleScreenController>();

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Agenda"),
        actionsPadding: const EdgeInsets.only(right: 8),
        automaticallyImplyLeading: false,
        leading: const BackButtonBelluga(),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _navigateToSearch,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.surfaceDim,
                  child: const DateRow(),
                ),
              ),
            ],
          ),
          Expanded(
              child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: StreamValueBuilder<List<EventModel>?>(
                  streamValue: _controller.eventsStreamValue,
                  onNullWidget: const Center(
                    child: CircularProgressIndicator(),
                  ),
                  builder: (context, events) {
                    final data = events ?? [];
                    if (data.isEmpty) {
                      return const Center(
                        child: Text('Nenhum evento nesta data.'),
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        children: data
                            .map((event) => EventCard(event: event))
                            .toList(),
                      ),
                    );
                  }),
            ),
          )),
        ],
      ),
    );
  }

  void _navigateToSearch() {
    context.router.push(const EventSearchRoute());
  }
}
