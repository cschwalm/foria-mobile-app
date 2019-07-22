import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/home.dart';
import 'package:foria/login.dart';
import 'package:foria/screens/about.dart';
import 'package:foria/screens/support.dart';
import 'package:foria/utils.dart';

import 'screens/selected_ticket.dart';

void main() async {

  runApp(
      new MaterialApp(
        title: 'Foria',
        theme: new ThemeData(
//            primarySwatch: Colors.blueGrey,
//            scaffoldBackgroundColor: Colors.white,
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
              body1: TextStyle(fontSize: 18.0, color: Colors.grey[700]),
              body2: TextStyle(fontSize: 14.0, color: Colors.grey[700]),
              display1: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.black),
              headline: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.black,fontFamily: 'Rubik',),
            ),
        ),
        home: await isUserLoggedIn() ? new Home() : new Login(),
        routes: {
          '/login': (context) => Login(),
          '/home': (context) => Home(),
          '/support': (context) => About(),
          '/about': (context) => Support(),
          SelectedTicket.routeName: (context) => SelectedTicket(),
        }
    )
  );
}