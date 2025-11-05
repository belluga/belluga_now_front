import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant/screens/mercado/models/mercado_producer.dart';
import 'package:belluga_now/presentation/tenant/screens/mercado/producer_store_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'ProducerStoreRoute')
class ProducerStoreRoutePage extends StatelessWidget {
  const ProducerStoreRoutePage({
    super.key,
    required this.producer,
  });

  final MercadoProducer producer;

  @override
  Widget build(BuildContext context) {
    return ProducerStoreScreen(producer: producer);
  }
}
