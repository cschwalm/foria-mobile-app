import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/screens/venue_screen.dart';
import 'package:foria/utils/auth_utils.dart';

import 'home.dart';
import 'login.dart';

class SplashScreen extends StatefulWidget {
  static const routeName = '/splash-screen';

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {

  bool _loadLoginScreen = false;
  bool _loadVenueScreen = false;
  bool _loadHomeScreen = false;

  AnimationController controller;
  Animation<double> animation;

  initState() {
    super.initState();
    controller = AnimationController(
        duration: const Duration(seconds: 2), vsync: this);
    animation = CurvedAnimation(parent: controller, curve: Curves.easeIn);
 controller.forward();
  }

  @override
  void didChangeDependencies() {
    isUserLoggedIn(true).then((bool isUserLoggedIn){
      if (! isUserLoggedIn){
        setState(() {
          _loadLoginScreen = true;
        });
      } else {
        doesUserHaveVenueAccess().then((bool doesUserHaveVenueAccess){
          if (doesUserHaveVenueAccess){
            setState(() {
              _loadVenueScreen = true;
            });
          } else {
            setState(() {
              _loadHomeScreen = true;
            });
          }
        });
      }
    });
    super.didChangeDependencies();
  }

  Widget _buildChild() {
    if(_loadLoginScreen) {
      return Login();
    }
    if(_loadVenueScreen){
      return VenueScreen();
    }
    if(_loadHomeScreen){
      return Home();
    }
    return _splashScreenContents();
  }

  Widget _splashScreenContents(){
    return Container(
      color: Colors.white,
      child: Center(
        child: _loadLoginScreen ? Login() :
        Container(
            width: 200,
            child: FadeTransition(
              opacity: animation,
              child: Image.asset(
                'assets/images/foria-logo.png',
              ),
            )
        ),
      ),
    );
  }
  Widget build(BuildContext context) {

    return _buildChild();
  }
}

