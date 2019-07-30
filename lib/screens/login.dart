import 'package:flutter/material.dart';
import 'package:foria/utils/utils.dart';

class Login extends StatelessWidget {

  static const routeName = '/login';

  ///
  /// Returns a centered application logo.
  ///
  Widget getLogoWidget() {
    return new Padding(
        padding: EdgeInsets.only(top: 50),
        child: new ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: 300,
              maxWidth: 300,
              minHeight: 200,
              maxHeight: 200,
            ),
            child:
            DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/foria-logo.png'),
                  // ...
                ),
                // ...
              ),
            )
        )
    );
  }

  Widget getAuthButton(BuildContext context) {
    return new Expanded(
      child: new Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: 100,
            width: double.infinity,
              child: RaisedButton(
                color: Color.fromRGBO(254, 199, 0, 1),
                onPressed: () => {
                webLogin(context)
                },
                child: Text(
                  'Log In / Register',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold
                  ),
                ),
              ))
      ),
    );
  }

  @override
  Widget build (BuildContext context) => new Scaffold(
      backgroundColor: Colors.white,
      body: new Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          getLogoWidget(),
          getAuthButton(context)
        ],
      )
  );
}

