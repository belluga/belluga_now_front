import 'package:flutter/material.dart';
import 'package:unifast_portal/domain/courses/file_model.dart';
import 'package:unifast_portal/presentation/common/widgets/image_with_progress_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

class FileCard extends StatefulWidget {
  final FileModel fileModel;
  final int index;

  const FileCard({super.key, required this.fileModel, required this.index});

  @override
  State<FileCard> createState() => _FileCardState();
}

class _FileCardState extends State<FileCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: _openFileExternal,
        child: Container(
          color: Theme.of(context).colorScheme.surfaceDim,
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 56,
                width: 56,
                child: ImageWithProgressIndicator(thumb: widget.fileModel.thumb),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsetsGeometry.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.fileModel.title.valueFormated,
                        maxLines: 2,
                        style: TextTheme.of(context).labelMedium,
                      ),
                      SizedBox(height: 8),
                      Text(
                        widget.fileModel.description.valueFormated,
                        maxLines: 3,
                        style: TextTheme.of(
                          context,
                        ).bodySmall?.copyWith(fontWeight: FontWeight.w300),
                      ),
                    ],
                  ),
                ),
              ),
              Icon(Icons.link),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openFileExternal() async {
    final url = widget.fileModel.url.value!;
    try {
      await launchUrl(url);
    } catch (e) {
      _showSnackBar();
    }
  }

  void _showSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        content: Text(
          'O arquivo ${widget.fileModel.title.valueFormated} não pôde ser baixado. Tente mais tarde.',
          style: TextTheme.of(context).bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
      ),
    );
  }
}
