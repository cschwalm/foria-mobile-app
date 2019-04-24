import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:foria/home.dart';
import 'package:foria/login.dart';

void main() => runApp(new MaterialApp(
  title: 'Foria',
  theme: new ThemeData(
      primarySwatch: Colors.blueGrey,
      scaffoldBackgroundColor: Colors.white,
      primaryColor: Colors.blueGrey,
      backgroundColor: Colors.white
  ),
  home: Login(),
  routes: {
    '/login': (context) => Login(),
    '/home': (context) => Home(),
  }
));