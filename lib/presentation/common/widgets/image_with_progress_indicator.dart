import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/thumb_model.dart';

class ImageWithProgressIndicator extends StatelessWidget {
  final ThumbModel thumb;
  final double? width;
  final double? height;

  const ImageWithProgressIndicator({
    super.key,
    required this.thumb,
    this.width = 80,
    this.height = 80,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.horizontal(left: Radius.circular(8)),
              image: DecorationImage(
                image: Image.network(thumb.thumbUri.toString()).image,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
