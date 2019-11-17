

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/utils/constants.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria/widgets/primary_button.dart';
import 'package:foria/widgets/settings_item.dart';

class IntroScreenTwo extends StatefulWidget {
  
  static const routeName = '/intro-screen-two';

  @override
  _IntroScreenTwoState createState() => _IntroScreenTwoState();
}

class _IntroScreenTwoState extends State<IntroScreenTwo> {

  bool isChecked = false;

  Widget _bodyText() {
    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: <Widget>[
          Text(
              introForiaHeaderTwo,
              style: Theme.of(context).textTheme.headline
          ),
          SizedBox(height: 16),
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.body1,
              children: <TextSpan>[
                TextSpan(text: 'You can’t send screenshots to friends, but '),
                TextSpan(text: 'transfers are a breeze!\n\n', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                TextSpan(text: 'Simply click the transfer button below the Foria Pass barcode and enter your' +
                    'friend’s email. friend’s email. \n\n Please note that your friend will need the Foria App' +
                    'to receive Foria Passes.'),
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
                  height: 250,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0,20,0,0),
                    child: Center(
                      child: Image.asset(
                        introQrGif,
                        width: 170,
                        height: 170,
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(height: 40),
                    Container(
                      height: 10,
                      width: 10,
                      decoration: new BoxDecoration(
                        color: Colors.grey[350],
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 20),
                    Container(
                      height: 10,
                      width: 10,
                      decoration: new BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),

              ],
            ),
            Expanded(child: _bodyText()),
            SettingItemDivider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: PrimaryButton(
                text: introForiaButtonTwo,
              ),
            )
          ],
        ),
      ),
    );
  }
}
