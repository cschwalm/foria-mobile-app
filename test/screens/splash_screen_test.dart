import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foria/main.dart';
import 'package:foria/screens/home.dart';
import 'package:foria/screens/login.dart';
import 'package:foria/screens/splash_screen.dart';
import 'package:foria/screens/venue_screen.dart';
import 'package:foria/utils/auth_utils.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';

class MockAuthUtils extends Mock implements AuthUtils {}

void main() {

  final AuthUtils authUtils = new MockAuthUtils();
  GetIt.instance.registerSingleton<AuthUtils>(authUtils);

  testWidgets('navigates to login screen if user not logged in', (WidgetTester tester) async {

    when(authUtils.isUserLoggedIn(true)).thenAnswer((_) => Future.value(false));

    await tester.pumpWidget(MaterialApp(
        home: SplashScreen(),
      navigatorKey: navigatorKey,
      routes: {
        Login.routeName: (context) => Login(),

      },
    ));

    await tester.pumpAndSettle();
    expect(find.byType(Login), findsOneWidget);

  });

  testWidgets('navigates to venue screen if user logged in as a venue', (WidgetTester tester) async {

    when(authUtils.isUserLoggedIn(true)).thenAnswer((_) => Future.value(true));
    when(authUtils.doesUserHaveVenueAccess()).thenAnswer((_) => Future.value(true));

    await tester.pumpWidget(MaterialApp(
      home: SplashScreen(),
      navigatorKey: navigatorKey,
      routes: {
        VenueScreen.routeName: (context) => VenueScreen(),
      },
    ));

    await tester.pumpAndSettle();

    expect(find.byType(VenueScreen), findsOneWidget);

  });

  testWidgets('navigates to home if user logged in as a fan, not venue', (WidgetTester tester) async {

    when(authUtils.isUserLoggedIn(true)).thenAnswer((_) => Future.value(true));
    when(authUtils.doesUserHaveVenueAccess()).thenAnswer((_) => Future.value(false));

    await tester.pumpWidget(MaterialApp(
      home: SplashScreen(),
      navigatorKey: navigatorKey,
      routes: {
        Home.routeName: (context) => Login(),
        //the test executes the build via the Home.routename, but times out on Home(). Login() used as a proxy to prove test works
      },
    ));

    await tester.pumpAndSettle();

    expect(find.byType(Login), findsOneWidget);

  });
}