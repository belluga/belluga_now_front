import 'dart:async';

import 'package:belluga_now/presentation/prototypes/map_experience/controllers/map_screen_controller.dart';
import 'package:belluga_now/presentation/prototypes/map_experience/widgets/map_header.dart';
import 'package:belluga_now/presentation/prototypes/map_experience/widgets/fab_menu.dart';
import 'package:belluga_now/presentation/prototypes/map_experience/widgets/poi_details_deck.dart';
import 'package:belluga_now/presentation/prototypes/map_experience/widgets/prototype_map_layers.dart';
import 'package:belluga_now/presentation/prototypes/map_experience/widgets/status_banner.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class MapExperiencePrototypeScreen extends StatefulWidget {
  const MapExperiencePrototypeScreen({super.key});

  @override
  State<MapExperiencePrototypeScreen> createState() =>
      _MapExperiencePrototypeScreenState();
}

class _MapExperiencePrototypeScreenState
    extends State<MapExperiencePrototypeScreen> {
  final _controller = GetIt.I.get<MapScreenController>();

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final scheme = ColorScheme.fromSeed(
      seedColor: base.colorScheme.primary,
      brightness: base.brightness,
    );
    final theme = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.black,
      textTheme: base.textTheme.apply(fontFamily: 'Roboto'),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: PrototypeMapLayers(),
                ),
              ],
            ),
            // SafeArea(
            //   child: SizedBox(
            //     height: 120,
            //     child: Padding(
            //       padding: const EdgeInsets.symmetric(horizontal: 16),
            //       child: Column(
            //         crossAxisAlignment: CrossAxisAlignment.stretch,
            //         children: [
            //           MapHeader(onSearch: _openSearchDialog),
            //           const SizedBox(height: 8),
            //           StatusBanner(),
            //         ],
            //       ),
            //     ),
            //   ),
            // ),
            Positioned(
              left: 16,
              right: 96,
              bottom: 16,
              child: SafeArea(
                child: PoiDetailDeck(),
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: FabMenu(
          onNavigateToUser: _centerOnUser,
        ),
      ),
    );
  }

  Future<void> _openSearchDialog() async {
    final controller = TextEditingController();
    final query = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buscar pontos'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration:
              const InputDecoration(hintText: 'Digite o termo de busca'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
    if (query == null) {
      return;
    }
    if (query.trim().isEmpty) {
      await _controller.clearSearch();
    } else {
      await _controller.searchPois(query.trim());
    }
  }

  Future<void> _initializeController() async {
    await _controller.init();
  }

  Future<void> _centerOnUser() async {
    final message = await _controller.centerOnUser();
    if (!mounted || message == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
