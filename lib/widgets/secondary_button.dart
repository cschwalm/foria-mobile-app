import 'package:flutter/material.dart';
import 'package:foria/main.dart' as theme;


class SecondaryButton extends StatelessWidget {

  final Function onPress;
  final String text;
  final double minSize;
  final BorderRadius borderRadius;


  SecondaryButton({
    @required this.onPress,
    @required this.text,
    this.minSize = 44.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(8.0)),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPress,
      child: Semantics(
        button: true,
        child: ConstrainedBox(
          constraints: minSize == null
              ? const BoxConstraints()
              : BoxConstraints(
            minWidth: minSize,
            minHeight: minSize,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
                borderRadius: borderRadius,
                border: Border.all(
                  color: theme.shapeGreyColor,
                  width: 2.0,
                )
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(text),
              ],
            ),
          ),
        ),
      ),
    );
  }
}