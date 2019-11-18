

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/screens/intro_screen_two.dart';
import 'package:foria/utils/constants.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria/widgets/intro_screen_image.dart';
import 'package:foria/widgets/primary_button.dart';
import 'package:foria/widgets/settings_item.dart';

class IntroScreenOne extends StatefulWidget {

  static const routeName = '/intro-screen-one';

  @override
  _IntroScreenOneState createState() => _IntroScreenOneState();
}

class _IntroScreenOneState extends State<IntroScreenOne> {

  bool isChecked = false;

  Widget _bodyText() {
    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: <Widget>[
          Text(
            introForiaHeaderOne,
            style: Theme.of(context).textTheme.headline
          ),
          SizedBox(height: 16),
          RichText(
            text: TextSpan(
          style: Theme.of(context).textTheme.body1,
          children: <TextSpan>[
            TextSpan(text: 'To eliminate fraud, '),
            TextSpan(text: 'screenshots ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            TextSpan(text: 'of Foria Passes are '),
            TextSpan(text: 'not valid ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            TextSpan(text: 'and will be denied.\n\nForia uses rotating barcodes that change every 30 seconds.\n\n'),
            TextSpan(text: 'You can rest assured that every Foria Pass in this app is '),
            TextSpan(text: 'authentic.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          ],
        ),
      )
    ]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: constPrimaryColorDark,
        title: Text(introToForia),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            IntroScreenImage(introQrGif,150,150),
            Expanded(child: _bodyText()),
            SettingItemDivider(),
            CheckboxListTile(
              title: Text(screenshotCheckbox),
              value: isChecked,
              onChanged: (bool value) {
                setState(() {
                  isChecked = value;
                });
              },
            ),
            SettingItemDivider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: PrimaryButton(
                text: introForiaButtonOne,
                isActive: isChecked,
                onPress: isChecked ? () => Navigator.of(context).pushNamed(IntroScreenTwo.routeName) : null,
              ),
            )
          ],
        ),
      ),
    );
  }
}
