import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';


/// Shows the user a generic error message.
void showPopUpConfirm(BuildContext context, String title, String body,[Function function]) {

  AlertDialog alert = AlertDialog(
    title: Text(title),
    content: Text(body),
    actions: [
      FlatButton(
        child: Text("Yes"),
        onPressed: () async {
          if (function != null) {
            await function();
          }
          Navigator.of(context).pop();
        },
      ),
      FlatButton(
        child: Text("No"),
        onPressed: () => Navigator.of(context).pop(),
      ),
    ],
  );

  CupertinoAlertDialog cupertinoAlert = CupertinoAlertDialog(
    title: Text(title),
    content: Text(body),
    actions: <Widget>[
      CupertinoDialogAction(
        isDefaultAction: true,
        child: Text("Yes"),
        onPressed: () async {
          if (function != null) {
            await function();
          }
          Navigator.of(context).pop();
        },
      ),
      CupertinoDialogAction(
        child: Text("No"),
        onPressed: () => Navigator.of(context).pop(),
      )
    ],
  );

  showDialog(
    context: context,
    builder: (BuildContext context) {
      if (Platform.isIOS) {
        return cupertinoAlert;
      } else {
        return alert;
      }
    },
  );
}