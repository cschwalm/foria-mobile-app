import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/utils/strings.dart';

Future<void> confirmEmailPopUp(BuildContext context) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return CupertinoAlertDialog(
        title: Text(emailConfirmationRequired),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              SizedBox(height: 5,),
              Text(pleaseConfirmEmail),
            ],
          ),
        ),
        actions: <Widget>[
          FlatButton(
            child: Text(iveConfirmedEmail,
              style: TextStyle(color: Theme.of(context).primaryColor),),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}