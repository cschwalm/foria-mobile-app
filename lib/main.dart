import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/home.dart';
import 'package:foria/login.dart';
import 'package:foria/utils.dart';

void main() async {

  runApp(
      new MaterialApp(
        title: 'Foria',
        theme: new ThemeData(
            primarySwatch: Colors.blueGrey,
            scaffoldBackgroundColor: Colors.white,
            primaryColor: Colors.blueGrey,
            backgroundColor: Colors.white
        ),
        home: await isUserLoggedIn() ? new Home() : new Login(),
        routes: {
          '/login': (context) => Login(),
          '/home': (context) => Home(),
        }
    )
  );
}