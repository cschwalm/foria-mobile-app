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

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}