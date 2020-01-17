import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/main.dart';
import 'package:foria/utils/auth_utils.dart';
import 'package:get_it/get_it.dart';
import 'package:quick_actions/quick_actions.dart';

///
/// First screen shown to user. Transitions away automatically.
import 'home.dart';
import 'login.dart';

///
/// First screen user is shown. Loads token from disk and parses before advancing.
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

    //Wait until the token is parsed before advancing. This ensures future tabs can depend on AuthUtils data.
    final AuthUtils authUtils = GetIt.instance<AuthUtils>();
    authUtils.isUserLoggedIn(true).then((isLoggedIn) {

      authUtils.isVenue.then((isVenue) {

        if (isVenue) {

          final List<ShortcutItem> list = new List<ShortcutItem>();
          final QuickActions quickActions = new QuickActions();
          list.add(const ShortcutItem(type: 'ACTION_SCAN', localizedTitle: 'Scan Tickets', icon: 'ic_action_scan'));
          quickActions.setShortcutItems(list);
        }
      });

      controller.addStatusListener((AnimationStatus status) {

        if (status == AnimationStatus.completed) {
          _determineNavigationRoute(isLoggedIn);
        }
      });
    });

    controller.forward();
  }

  ///
  /// Sends user to login screen if not logged in.
  ///
  Future<void> _determineNavigationRoute(bool isLoggedIn) async {

    if (!isLoggedIn) {
      navigatorKey.currentState.pushReplacementNamed(Login.routeName);
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

