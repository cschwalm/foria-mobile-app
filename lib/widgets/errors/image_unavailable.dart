import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/utils/strings.dart';

class ImageUnavailable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(Icons.error, color: Colors.red,),
        Text(imageUnavailable,textAlign: TextAlign.center,)
      ],
    );
  }
}
