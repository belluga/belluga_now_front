import 'package:flutter/material.dart';

class PendingDocumentsDashboard extends StatefulWidget {
  const PendingDocumentsDashboard({super.key});

  @override
  State<PendingDocumentsDashboard> createState() =>
      _PendingDocumentsDashboardState();
}

class _PendingDocumentsDashboardState extends State<PendingDocumentsDashboard> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceDim,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.alarm),
            SizedBox(width: 24),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Documentos Pendentes",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    "Envie os documentos o quanto antespara que você possa dar sequência nos seus estudos.",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            SizedBox(width: 24),
            Icon(Icons.arrow_forward_ios),
          ],
        ),
      ),
    );
  }
}
