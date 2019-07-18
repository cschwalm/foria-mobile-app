import 'package:flutter/material.dart';
import 'package:foria/utils.dart';

class AccountTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => new Container(
    child: new Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        new Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            RaisedButton(
              onPressed: () {
                logout(context);
              },
              child: Text(
                'Logout',
                textAlign: TextAlign.center,
              ),
            )
          ],
        ),
      ],
    ),
  );
}