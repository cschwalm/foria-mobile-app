
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/utils/constants.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria/widgets/intro_screen_image.dart';
import 'package:foria/widgets/primary_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home.dart';

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
                TextSpan(text: 'Simply click the transfer button below the Foria Pass barcode and enter your ' +
                    'friend’s email.\n\nPlease note that your friend must create a Foria account to accept your transfer'),
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
            IntroScreenImage(introTransferImage, 150, 170),
            Expanded(child: _bodyText()),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: PrimaryButton(
                text: introForiaButtonTwo,
                onPress: () async {
                  SharedPreferences pref = await SharedPreferences.getInstance();
                  pref.setBool('viewedForiaIntro', true);
                  Navigator.of(context).pushNamed(Home.routeName);
                }
              ),
            )
          ],
        ),
      ),
    );
  }
}
