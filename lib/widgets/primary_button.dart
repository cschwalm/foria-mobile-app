import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:foria/main.dart' as theme;

class PrimaryButton extends StatelessWidget {
  final String text;
  final Function onPress;
  final IconData icon;
  final bool isActive;
  final double minSize;

  PrimaryButton({
    @required this.text,
    @required this.onPress,
    this.icon,
    this.isActive = true,
    this.minSize = 44,
  });


  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minSize: minSize,
      padding: EdgeInsets.zero,
      color: isActive ? Theme.of(context).primaryColor : theme.shapeGrey,
      onPressed: onPress,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (icon != null)
          Icon(icon),
          if (icon != null)
            SizedBox(
              width: 10,
            ),
          Text(
            text,
            style: Theme.of(context).textTheme.button,
          ),
        ],
      ),
    );
  }
}
