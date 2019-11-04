import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:foria/utils/constants.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final Function onPress;
  final IconData icon;
  final bool isActive;
  final bool isLoading;
  final double minSize;

  PrimaryButton({
    @required this.text,
    @required this.onPress,
    this.icon,
    this.isActive = true,
    this.isLoading = false,
    this.minSize = 44,
  });

  Widget _buttonContent(BuildContext context) {
    return Row(
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
    );
  }

  Widget _loadingContent () {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        CupertinoActivityIndicator(),
      ],
    );
  }
  static const deviceConflictKey = 'device_conflict_key';

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      key: Key(deviceConflictKey),
      minSize: minSize,
      padding: EdgeInsets.zero,
      color: Theme.of(context).primaryColor,
      disabledColor: isActive ? Theme.of(context).primaryColor : textGreyColor,
      onPressed: onPress,
      child: isLoading ? _loadingContent() : _buttonContent(context),
    );
  }
}
