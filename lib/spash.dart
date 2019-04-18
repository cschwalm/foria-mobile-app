import 'package:flutter/material.dart';

class Splash extends StatelessWidget {

  ///
  /// Returns a centered application logo.
  ///
  Widget getLogoWidget() {
    return new Align(
        alignment: new Alignment(0, -1000),
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
                  image: AssetImage('assets/images/red-logo.png'),
                  // ...
                ),
                // ...
              ),
            )
        )
    );
  }

  Widget getAuthButton() {
    return new Align(
          alignment: Alignment.bottomCenter,
          child: RaisedButton(
            color: Color.fromRGBO(100, 78, 0, 1),
            onPressed: () =>
            {
            debugPrint("Im tapped")
            },
            child: const Text('Log In / Register'),
          ),
        );
  }

  @override
  Widget build (BuildContext context) => new Scaffold(
      backgroundColor: Colors.white,
      body: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          getLogoWidget(),
          getAuthButton()
        ],
      )
  );
}

