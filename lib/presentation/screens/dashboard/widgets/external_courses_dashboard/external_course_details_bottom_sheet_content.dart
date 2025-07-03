import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/external_course/external_course.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/common/widgets/image_with_progress_indicator.dart';

class ExternalCourseDetailsBottomSheetContent extends StatelessWidget {
  final ExternalCourse course;
  final Function() onExternalLinkClick;

  const ExternalCourseDetailsBottomSheetContent({
    super.key,
    required this.course,
    required this.onExternalLinkClick,
  });

  @override
  Widget build(BuildContext context) {
    // The main column holds all the content.
    // We remove the default padding to allow the image to span the full width.
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. A visual handle to indicate the sheet is draggable
          Center(
            child: Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.symmetric(vertical: 12.0),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          ImageWithProgressIndicator(thumbUrl: course.thumbUrl.value),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title.valueFormated,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  course.description.value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onExternalLinkClick,
                  icon: const Icon(
                    Icons.open_in_new,
                  ), // A fitting icon for an external link
                  label: const Text('Acessar o curso'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(
                      double.infinity,
                      50,
                    ), // Full-width and taller button
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
