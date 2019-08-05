import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria/utils/utils.dart';

import 'home.dart';

class EmailVerificationFailure extends StatelessWidget {

  static const routeName = '/email_not_verified';

  @override
  Widget build (BuildContext context) => new Scaffold(
      backgroundColor: Colors.white,
      body: CupertinoAlertDialog(
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
            onPressed: () async {
              await forceTokenRefresh();

              if (await isUserEmailVerified()) {
                Navigator.pushNamed(context, Home.routeName);
              }
            },
          ),
        ],
      )
  );
}
