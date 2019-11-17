

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/screens/intro_screen_two.dart';
import 'package:foria/utils/constants.dart';
import 'package:foria/utils/strings.dart';
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
            Stack(
              alignment: Alignment.topCenter,
              children: <Widget>[
                Container(
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
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0,20,0,0),
                    child: Center(
                      child: Image.asset(
                        introQrGif,
                        width: 150,
                        height: 150,
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(height: 40,),
                    Container(
                      height: 10,
                      width: 10,
                      decoration: new BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 20,),
                    Container(
                      height: 10,
                      width: 10,
                      decoration: new BoxDecoration(
                        color: Colors.grey[350],
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),

              ],
            ),
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
                onPress: () => Navigator.of(context).pushNamed(IntroScreenTwo.routeName),
              ),
            )
          ],
        ),
      ),
    );
  }
}
