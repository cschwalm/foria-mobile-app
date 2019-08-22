import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show DeviceOrientation, SystemChrome;
import 'package:flutter/services.dart';
import 'package:foria/screens/splash_screen.dart';
import 'package:foria/screens/venue_screen.dart';

import 'navigation/CustomNoTransition.dart';
import 'screens/home.dart';
import 'screens/login.dart';
import 'screens/selected_ticket_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

const Color textGreyColor = Color(0xFFC7C7C7);
const Color shapeGreyColor = Color(0xFFC7C7C7);
const Color settingsBackgroundColor = Color(0xffEEEEEE);

void main() async {

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
      new MaterialApp(
        title: 'Foria',
        navigatorKey: navigatorKey,
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

        onGenerateRoute: (RouteSettings settings) {

          switch (settings.name) {

            case Home.routeName:
              return MaterialPageRoute(builder: (context)=> Home(), settings: settings);
              break;

            case Login.routeName:
              return CustomNoTransition(builder: (context)=> Login(), settings: settings);
              break;

            case SelectedTicketScreen.routeName:
              return MaterialPageRoute(builder: (context)=> SelectedTicketScreen(), settings: settings);
              break;

            case VenueScreen.routeName:
              return MaterialPageRoute(builder: (context)=> VenueScreen(), settings: settings);
              break;

            default:
              return CustomNoTransition(builder: (context)=> SplashScreen(), settings: settings);
              break;
          }
        }
    )
  );
}
