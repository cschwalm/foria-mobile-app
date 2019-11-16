import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Shows the user a generic error message.
void showErrorAlert(BuildContext context, String error, [Function dismissAction]) {

  Widget okButton = FlatButton(

    child: Text("OK"),
    onPressed: () async {
      if (dismissAction != null) {
        await dismissAction();
      }
      Navigator.of(context).pop();
    },
  );

  AlertDialog alert = AlertDialog(
    title: Text("Error"),
    content: Text(error),
    actions: [
      okButton,
    ],
  );

  CupertinoAlertDialog cupertinoAlert = CupertinoAlertDialog(
    title: Text("Error"),
    content: Text(
        error,
      style: Theme.of(context).textTheme.body2,
    ),
    actions: <Widget>[
      CupertinoDialogAction(
        isDefaultAction: true,
        child: Text("OK"),
        onPressed: () async {
          if (dismissAction != null) {
            await dismissAction();
          }
          Navigator.of(context).pop();
        },
      ),
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