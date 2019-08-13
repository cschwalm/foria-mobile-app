import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  static const routeName = '/splash-screen';

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {

  AnimationController controller;
  Animation<double> animation;

  initState() {
    super.initState();
    controller = AnimationController(
        duration: const Duration(seconds: 3), vsync: this);
    animation = CurvedAnimation(parent: controller, curve: Curves.easeIn);
 controller.forward();
  }

  Widget build(BuildContext context) {

    return Container(
      color: Colors.white,
      child: Center(
        child: Container(
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
}


