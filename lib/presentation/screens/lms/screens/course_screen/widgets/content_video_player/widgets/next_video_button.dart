import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:unifast_portal/application/router/app_router.gr.dart';
import 'package:unifast_portal/domain/courses/course_base_model.dart';
import 'package:unifast_portal/presentation/common/widgets/image_with_progress_indicator.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/course_screen/widgets/content_video_player/controller/next_video_button_controller.dart';

class NextVideoButton extends StatefulWidget {
  final CourseBaseModel courseItem;
  final double videoPercentage;

  const NextVideoButton({
    super.key,
    required this.courseItem,
    this.videoPercentage = 1,
  });

  @override
  State<NextVideoButton> createState() => _NextVideoButtonState();
}

class _NextVideoButtonState extends State<NextVideoButton> {
  final _controller = NextVideoButtonController();

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final _buttonOpacity = _controller.getButtonOpacity(
          widget.videoPercentage,
        );

        return SizedBox(
          width: 130,
          child: InkWell(
            onTap: _navigateToNext,
            child: AnimatedOpacity(
              opacity: _buttonOpacity,
              duration: Duration(milliseconds: 0),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceDim,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image: NetworkImage(widget.courseItem.thumb.thumbUri.toString(),
                                          ),
                                          colorFilter: ColorFilter.mode(
                                            Colors.black.withAlpha(150),
                                            BlendMode.darken,
                                          ),
                                          fit: BoxFit.cover,
                                        ),  
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Icon(Icons.fast_forward),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.courseItem.title.value,
                            maxLines: 2,
                            style: TextTheme.of(context).labelSmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateToNext() {
    GetIt.I.pushNewScope(scopeName: widget.courseItem.id.value);
    context.router.pop();
    context.router.push(CourseRoute(
      courseItemId: widget.courseItem.id.value));
  }
}
