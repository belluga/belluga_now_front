import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class ExternalCourseUrlDialog extends StatefulWidget {
  final Function(bool?) savePreferences;
  final StreamValue<bool> isCheckedStreamValue;
  final Future<void> Function() launchURL;

  const ExternalCourseUrlDialog({
    super.key,
    required this.savePreferences,
    required this.isCheckedStreamValue,
    required this.launchURL,
  });

  @override
  State<ExternalCourseUrlDialog> createState() =>
      _ExternalCourseUrlDialogState();
}

class _ExternalCourseUrlDialogState extends State<ExternalCourseUrlDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Aviso de Link Externo'),
      content: StatefulBuilder(
        // StatefulBuilder permite que a checkbox tenha seu próprio estado.
        builder: (BuildContext context, StateSetter setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'O conteúdo que você está prestes a acessr é fornecido por um parceiro em uma plataforma externa. Deseja continuar?',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  StreamValueBuilder(
                    streamValue: widget.isCheckedStreamValue,
                    builder: (context, isChecked) {
                      return Checkbox(
                        value: isChecked,
                        onChanged: widget.savePreferences,
                      );
                    },
                  ),
                  const Flexible(child: Text('Não me pergunte novamente')),
                ],
              ),
            ],
          );
        },
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancelar'),
          onPressed: () {
            context.router.pop();
          },
        ),
        ElevatedButton(
          child: const Text('Continuar'),
          onPressed: () async {
            context.router.pop();

            // Abre a URL.
            widget.launchURL();
          },
        ),
      ],
    );
  }
}
