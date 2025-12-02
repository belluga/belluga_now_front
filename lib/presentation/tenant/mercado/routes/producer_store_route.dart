import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/mercado_module.dart';
import 'package:belluga_now/presentation/tenant/mercado/models/mercado_producer.dart';
import 'package:belluga_now/presentation/tenant/mercado/screens/producer_store_screen/producer_store_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'ProducerStoreRoute')
class ProducerStoreRoutePage extends StatelessWidget {
  const ProducerStoreRoutePage({
    super.key,
    required this.producer,
  });

  final MercadoProducer producer;

  @override
  Widget build(BuildContext context) {
    return ModuleScope<MercadoModule>(
      child: ProducerStoreScreen(producer: producer),
    );
  }
}
