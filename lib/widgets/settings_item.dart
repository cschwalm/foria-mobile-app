import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/utils/constants.dart';

// The widgets in this file present a Cupertino-style settings item to the user.
// In the future, the Cupertino package in the Flutter SDK will include
// dedicated widgets for this purpose, but for now they're done here.
//
// See https://github.com/flutter/flutter/projects/29 for more info.

typedef SettingsItemCallback = FutureOr<void> Function();

class SettingsNavigationIndicator extends StatelessWidget {
  const SettingsNavigationIndicator({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Icon(
      CupertinoIcons.forward,
      color: Color(0xffc7c7c7),
      size: 21,
    );
  }
}

class SettingsIcon extends StatelessWidget {
  const SettingsIcon({
    @required this.icon,
    this.foregroundColor = CupertinoColors.white,
    this.backgroundColor = CupertinoColors.black,
    Key key,
  })  : assert(icon != null),
        super(key: key);

  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: backgroundColor,
      ),
      child: Center(
        child: Icon(
          icon,
          color: foregroundColor,
          size: 20,
        ),
      ),
    );
  }
}

class SettingsItem extends StatefulWidget {
  const SettingsItem({
    @required this.label,
    this.icon,
    this.content,
    this.subtitle,
    this.onPress,
    this.labelTextStyle,
    Key key,
  })  : assert(label != null),
        super(key: key);

  final String label;
  final Widget icon;
  final Widget content;
  final String subtitle;
  final SettingsItemCallback onPress;
  final TextStyle labelTextStyle;

  @override
  State<StatefulWidget> createState() => SettingsItemState();
}

class SettingsItemState extends State<SettingsItem> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: pressed ? Color(0xffd9d9d9) : Color(0xffFFFFFF),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          if (widget.onPress != null) {
            setState(() {
              pressed = true;
            });
            await widget.onPress();
            Future.delayed(
              Duration(milliseconds: 150),
              () {
                setState(() {
                  pressed = false;
                });
              },
            );
          }
        },
        child: SizedBox(
          height: widget.subtitle == null ? 44 : 57,
          child: Row(
            children: [
              if (widget.icon != null)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 15,
                    bottom: 2,
                  ),
                  child: SizedBox(
                    height: 29,
                    width: 29,
                    child: widget.icon,
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 15,
                  ),
                  child: widget.subtitle != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SizedBox(height: 8.5),
                            Text(
                              widget.label,
                              style: Theme.of(context).textTheme.title,
                            ),
                            SizedBox(height: 4),
                            Text(
                              widget.subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        )
                      : Padding(
                          padding: EdgeInsets.only(top: 1.5),
                          child: Text(
                            widget.label,
                            style: widget.labelTextStyle == null
                                ? Theme.of(context).textTheme.title
                                : widget.labelTextStyle,
                          ),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 11),
                child: widget.content ?? Container(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingItemDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xffbcbbc1),
      height: 0.3,
    );
  }
}

class MajorSettingItemDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SettingItemDivider(),
        Container(
          color: settingsBackgroundColor,
          height: 20,
        ),
        SettingItemDivider(),
      ],
    );
  }
}
