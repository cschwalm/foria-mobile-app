import 'package:flutter/material.dart';
import 'package:foria/utils.dart';

class AccountTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => new Container(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: new Column(
        crossAxisAlignment: CrossAxisAlignment.center,
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
                  'Contsct Us',
                  textAlign: TextAlign.center,
                ),
              ),
              RaisedButton(




                onPressed: () {
                  logout(context);
                },
                child: Text(
                  'Logout',

                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}