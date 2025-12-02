import 'package:flutter/cupertino.dart';
import 'package:belluga_now/domain/schedule/event_action_model/event_action_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:value_object_pattern/domain/value_objects/uri_value.dart';

class EventActionExternalNavigation extends EventActionModel {
  final URIValue externalUrl;

  EventActionExternalNavigation({
    required super.id,
    required super.label,
    required super.color,
    required this.externalUrl,
  });

  @override
  void open(BuildContext context) async {
    launchUrl(externalUrl.value!);
  }
}
