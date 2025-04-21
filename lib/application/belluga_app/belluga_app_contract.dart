import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl_standalone.dart';

abstract class BellugaAppContract {
  BellugaAppContract();

  final navigatorKey = GlobalKey<NavigatorState>();

  @mustCallSuper
  Future<void> initialize() async {

    WidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting();
    await _initLocalization();
    
  }

  Future<void> _initLocalization() async {
    await findSystemLocale();
  }
}
