import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/external_course/external_course.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/common/widgets/image_with_progress_indicator.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/dashboard/controllers/external_course_dashboard_controller.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/dashboard/widgets/external_courses_dashboard/external_course_details_bottom_sheet_content.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/dashboard/widgets/external_courses_dashboard/external_course_url_dialog.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';

class ExternalCourseCard extends StatefulWidget {
  final ExternalCourse course;

  const ExternalCourseCard({super.key, required this.course});

  @override
  State<ExternalCourseCard> createState() => _ExternalCourseCardState();
}

class _ExternalCourseCardState extends State<ExternalCourseCard> {
  final _controller = GetIt.I.get<ExternalCourseDashboardController>();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _showCourseDetailsBottomModal,
      child: Card.filled(
        color: Theme.of(context).colorScheme.surfaceDim,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ImageWithProgressIndicator(thumbUrl: widget.course.thumbUrl.value),
            Expanded(
              child: Padding(
                padding: EdgeInsetsGeometry.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.course.title.valueFormated,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      widget.course.description.value,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 80,
              child: IconButton(
                onPressed: _showExternalLinkConfirmation,
                icon: Icon(Icons.open_in_new),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCourseDetailsBottomModal() async {
    return showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ExternalCourseDetailsBottomSheetContent(
          course: widget.course,
          onExternalLinkClick: _showExternalLinkConfirmation,
        );
      },
    );
  }

  Future<void> _showExternalLinkConfirmation() async {
    final dontAskAgain = _controller.navigationPreferenceStreamValue.value;

    if (dontAskAgain) {
      _launchURL();
      return;
    }

    _showDialog();
  }

  Future<void> _showDialog() async {
    return await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return ExternalCourseUrlDialog(
          isCheckedStreamValue: _controller.navigationPreferenceStreamValue,
          launchURL: _launchURL,
          savePreferences: _controller.saveUrlNavigationPreference,
        );
      },
    );
  }

  Future<void> _launchURL() async {
    if (await canLaunchUrl(widget.course.thumbUrl.value)) {
      await launchUrl(widget.course.thumbUrl.value);
    } else {
      _showSnackBar(widget.course.thumbUrl.value.toString());
    }
  }

  Future<void> _showSnackBar(String url) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Não foi possível abrir o link: $url')),
    );
  }
}
