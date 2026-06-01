import 'package:belluga_now/application/time/timezone_converter.dart';

final class EventInviteSharePayloadBuilder {
  EventInviteSharePayloadBuilder._();

  static ({String subject, String message}) build({
    required String eventName,
    required String location,
    required DateTime eventDateTime,
    required Uri publicUri,
  }) {
    final title = eventName.trim();
    final safeTitle = title.isEmpty ? 'esse evento' : title;
    final place = location.trim();
    final placeClause = place.isEmpty ? '' : ' em $place';
    final schedule = humanDateTime(eventDateTime);

    return (
      subject: 'Convite para $safeTitle',
      message:
          'Bora para $safeTitle?\nVai ser $schedule$placeClause.\n\nDetalhes: $publicUri',
    );
  }

  static String preview({
    required String eventName,
    required String location,
    required DateTime eventDateTime,
  }) {
    final title = eventName.trim();
    final safeTitle = title.isEmpty ? 'esse evento' : title;
    final place = location.trim();
    final placeClause = place.isEmpty ? '' : ' em $place';

    return 'Bora para $safeTitle? ${humanDateTime(eventDateTime)}$placeClause.';
  }

  static String humanDateTime(DateTime value) {
    final localDateTime = TimezoneConverter.utcToLocal(value);
    final weekday = _weekdays[localDateTime.weekday - 1];
    final month = _months[localDateTime.month - 1];
    final time = _humanTime(localDateTime);

    return '$weekday, ${localDateTime.day} de $month às $time';
  }

  static String _humanTime(DateTime value) {
    final hour = value.hour.toString();
    if (value.minute == 0) {
      return '${hour}h';
    }
    final minute = value.minute.toString().padLeft(2, '0');
    return '${hour}h$minute';
  }

  static const _weekdays = <String>[
    'segunda-feira',
    'terça-feira',
    'quarta-feira',
    'quinta-feira',
    'sexta-feira',
    'sábado',
    'domingo',
  ];

  static const _months = <String>[
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];
}
