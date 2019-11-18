
import 'package:flutter/cupertino.dart';
import 'package:foria/utils/constants.dart';

class IntroScreenImage extends StatelessWidget {

  final String imageAddress;
  final double height;
  final double width;

  IntroScreenImage(this.imageAddress, this.height, this.width);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // Box decoration takes a gradient
        gradient: LinearGradient(
          // Where the linear gradient begins and ends
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          // Add one stop for each color. Stops should increase from 0 to 1
          colors: [
            constPrimaryColor,
            constPrimaryLight,
          ],
        ),
      ),
      width: double.infinity,
      height: 230,
      child: Center(
        child: Image.asset(
          imageAddress,
          width: width,
          height: height,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
