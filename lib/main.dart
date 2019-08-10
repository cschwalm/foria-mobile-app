import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show DeviceOrientation, SystemChrome;
import 'package:foria/screens/venue_screen.dart';
import 'package:foria/utils/auth_utils.dart';

import 'screens/home.dart';
import 'screens/login.dart';
import 'screens/register_and_transfer_screen.dart';
import 'screens/selected_ticket_screen.dart';

void main() async {

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
      new MaterialApp(
        title: 'Foria',
        theme: new ThemeData(
            backgroundColor: Colors.white,
            appBarTheme: AppBarTheme(
              color: Color(0xFFC5003C),
            ),
            primaryColor: Color(0xFFFF0266),
            primaryColorDark: Color(0xFFC5003C),
            fontFamily: 'Rubik',
            textTheme: TextTheme(
              title: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              button: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.white),
              body1: TextStyle(fontSize: 18.0, color: Color(0xFF7E7E7E)),
              body2: TextStyle(fontSize: 14.0, color: Color(0xFF7E7E7E)),
              display1: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.black),
              headline: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.black,fontFamily: 'Rubik',),
            ),
        ),
        home: await _determineHomeWidget(),
        routes: {
          Home.routeName: (context) => Home(),
          Login.routeName: (context) => Login(),
          SelectedTicketScreen.routeName: (context) => SelectedTicketScreen(),
          RegisterAndTransferScreen.routeName: (context) => RegisterAndTransferScreen(),
          VenueScreen.routeName: (context) => VenueScreen(),
        }
    )
  );
}

Future<Widget> _determineHomeWidget() async {

  if (! await isUserLoggedIn(true)) {
    return Login();
  }

  return Home();
}

const Color textGreyColor = Color(0xFFC7C7C7);
const Color shapeGreyColor = Color(0xFFC7C7C7);
const Color settingsBackgroundColor = Color(0xffEEEEEE);
