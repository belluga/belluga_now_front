import 'package:flutter/material.dart';

enum TenantAdminImageSourceOption {
  device,
  web,
}

Future<TenantAdminImageSourceOption?> showTenantAdminImageSourceSheet({
  required BuildContext context,
  required String title,
}) {
  return showModalBottomSheet<TenantAdminImageSourceOption>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Do dispositivo'),
                subtitle: const Text('Selecionar imagem da galeria'),
                onTap: () {
                  Navigator.of(sheetContext).pop(
                    TenantAdminImageSourceOption.device,
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.link_outlined),
                title: const Text('Da web'),
                subtitle: const Text('Colar URL da imagem'),
                onTap: () {
                  Navigator.of(sheetContext).pop(
                    TenantAdminImageSourceOption.web,
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
