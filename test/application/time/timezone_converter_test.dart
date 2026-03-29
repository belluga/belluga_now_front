import 'package:belluga_now/application/time/timezone_converter.dart';
import 'package:belluga_now/domain/services/timezone_service_contract.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('uses registered timezone service for utcToLocal conversion', () {
    GetIt.I.registerSingleton<TimezoneServiceContract>(
      _FakeTimezoneService(hoursOffset: -3),
    );

    final result = TimezoneConverter.utcToLocal(
      DateTime.utc(2026, 3, 29, 23, 0),
    );

    expect(result.hour, 20);
    expect(result.isUtc, isFalse);
  });

  test('uses registered timezone service for localToUtc conversion', () {
    GetIt.I.registerSingleton<TimezoneServiceContract>(
      _FakeTimezoneService(hoursOffset: -3),
    );

    final local = DateTime(2026, 3, 29, 20, 0);
    final result = TimezoneConverter.localToUtc(local);

    expect(result, DateTime.utc(2026, 3, 29, 23, 0));
    expect(result.isUtc, isTrue);
  });

  test('falls back to native conversion when service is not registered', () {
    final utc = DateTime.utc(2026, 3, 29, 23, 0);

    final local = TimezoneConverter.utcToLocal(utc);
    final backToUtc = TimezoneConverter.localToUtc(local);

    expect(backToUtc.toUtc(), utc);
  });
}

class _FakeTimezoneService implements TimezoneServiceContract {
  _FakeTimezoneService({required this.hoursOffset});

  final int hoursOffset;

  @override
  DateTime utcToLocal(DateTime value) {
    final baseUtc = value.isUtc ? value : value.toUtc();
    final shifted = baseUtc.add(Duration(hours: hoursOffset));
    return DateTime(
      shifted.year,
      shifted.month,
      shifted.day,
      shifted.hour,
      shifted.minute,
      shifted.second,
      shifted.millisecond,
      shifted.microsecond,
    );
  }

  @override
  DateTime localToUtc(DateTime value) {
    final normalized = DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.second,
      value.millisecond,
      value.microsecond,
    );
    return DateTime.utc(
      normalized.year,
      normalized.month,
      normalized.day,
      normalized.hour,
      normalized.minute,
      normalized.second,
      normalized.millisecond,
      normalized.microsecond,
    ).subtract(Duration(hours: hoursOffset));
  }
}
