fluuter aimport 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foria/main.dart';
import 'package:foria/screens/login.dart';
import 'package:foria/screens/splash_screen.dart';
import 'package:foria/utils/auth_utils.dart';
import 'package:mockito/mockito.dart';

void main() {

  setUp(() {
//    when(isUserLoggedIn(true)).thenAnswer((_) => Future.value(false)); ///TBU when auth class is made
  });



  testWidgets('navigation to login screen', (WidgetTester tester) async {


    await tester.pumpWidget(MaterialApp(
        home: SplashScreen(),
      navigatorKey: navigatorKey,
      routes: {
        Login.routeName: (context) => Login(),
      },
    ));

    await tester.pump(Duration(seconds: 15)
    );

    await tester.pumpAndSettle();

    expect(find.byType(Login), findsOneWidget);

  });
}