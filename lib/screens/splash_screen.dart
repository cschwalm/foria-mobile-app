import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/main.dart';
import 'package:foria/screens/venue_screen.dart';
import 'package:foria/utils/auth_utils.dart';
import 'package:get_it/get_it.dart';

import 'home.dart';
import 'login.dart';

///
/// First screen shown to user. Transitions away automatically.
///
class SplashScreen extends StatefulWidget {

  static const routeName = '/splash-screen';

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {

  AnimationController controller;
  Animation<double> animation;

  @override
  initState() {

    super.initState();
    controller = AnimationController(duration: const Duration(seconds: 2), vsync: this);
    animation = CurvedAnimation(parent: controller, curve: Curves.easeIn);
    controller.forward();
    controller.addStatusListener((AnimationStatus status) {

      if (status == AnimationStatus.completed) {
        _determineNavigationRoute();
      }
    });
  }

  Future<void> _determineNavigationRoute() async {

    final AuthUtils authUtils = GetIt.instance<AuthUtils>();

    if (!await authUtils.isUserLoggedIn(true)) {
      navigatorKey.currentState.pushReplacementNamed(Login.routeName);
    } else if (await authUtils.doesUserHaveVenueAccess()) {
      navigatorKey.currentState.pushReplacementNamed(VenueScreen.routeName);
    } else {
      navigatorKey.currentState.pushReplacementNamed(Home.routeName);
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 50),
        child: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                  width: 200,
                  child: FadeTransition(
                    opacity: animation,
                    child: Image.asset(
                      'assets/images/foria-logo.png',
                    ),
                  )),
            ),
            Container(
              height: 70,
            ),
          ],
        ),
      ),
    );
  }
}

