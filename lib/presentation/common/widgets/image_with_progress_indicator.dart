import 'package:flutter/material.dart';

class ImageWithProgressIndicator extends StatelessWidget {
  final Uri thumbUrl;
  final double? width;
  final double? height;

  const ImageWithProgressIndicator({
    super.key,
    required this.thumbUrl,
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
                image: Image.network(thumbUrl.toString()).image,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
