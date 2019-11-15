import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show DeviceOrientation, SystemChrome;
import 'package:flutter/services.dart';
import 'package:foria/providers/attendee_provider.dart';
import 'package:foria/providers/event_provider.dart';
import 'package:foria/providers/ticket_provider.dart';
import 'package:foria/providers/venue_provider.dart';
import 'package:foria/screens/attendee_list_screen.dart';
import 'package:foria/screens/organizer_events_screen.dart';
import 'package:foria/screens/splash_screen.dart';
import 'package:foria/screens/ticket_scan_screen.dart';
import 'package:foria/screens/transfer_screen.dart';
import 'package:foria/screens/organizer_home_screen.dart';
import 'package:foria/utils/auth_utils.dart';
import 'package:foria/utils/constants.dart';
import 'package:foria/utils/database_utils.dart';
import 'package:foria/utils/message_stream.dart';
import 'package:get_it/get_it.dart';

import 'navigation/CustomNoTransition.dart';
import 'screens/home.dart';
import 'screens/login.dart';
import 'screens/my_tickets_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FirebaseAnalytics analytics = FirebaseAnalytics();

void mainDelegate() {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  setupDependencies();

  runZoned<Future<void>>(() async {
    runApp(
        new MaterialApp(
          // Text scaling for accessibility mode turned off with 1.0 scale factor
            builder: (context, child) {
              return MediaQuery(
                child: child,
                data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
              );
            },
            title: 'Foria',
            navigatorKey: navigatorKey,
            theme: new ThemeData(
              backgroundColor: Colors.white,
              appBarTheme: AppBarTheme(
                color: constPrimaryColorDark,
              ),
              primaryColor: constPrimaryColor,
              primaryColorDark: constPrimaryColorDark,
              fontFamily: 'Rubik',
              textTheme: TextTheme(
                title: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                button: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.white),
                body1: TextStyle(fontSize: 18.0, color: textGreyColor),
                body2: TextStyle(fontSize: 14.0, color: textGreyColor),
                display1: TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold, color: Colors.black),
                headline: TextStyle(
                  fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
            navigatorObservers: [
              FirebaseAnalyticsObserver(analytics: analytics),
            ],
            onGenerateRoute: (RouteSettings settings) {
              switch (settings.name) {
                case Home.routeName:
                  return MaterialPageRoute(builder: (context) => Home(), settings: settings);
                  break;

                case Login.routeName:
                  return CustomNoTransition(builder: (context) => Login(), settings: settings);
                  break;

                case MyTicketsScreen.routeName:
                  return MaterialPageRoute(builder: (context) => MyTicketsScreen(), settings: settings);
                  break;

                case TicketScanScreen.routeName:
                  return MaterialPageRoute(builder: (context) => TicketScanScreen(), settings: settings);
                  break;

                case OrganizerHomeScreen.routeName:
                  return MaterialPageRoute(builder: (context) => OrganizerHomeScreen(), settings: settings);
                  break;

                case OrganizerEventsScreen.routeName:
                  return MaterialPageRoute(builder: (context) => OrganizerEventsScreen(), settings: settings);
                  break;

                case AttendeeListScreen.routeName:
                  return MaterialPageRoute(builder: (context) => AttendeeListScreen(), settings: settings);
                  break;

                case TransferScreen.routeName:
                  return MaterialPageRoute(builder: (context) => TransferScreen(), settings: settings, fullscreenDialog: true);
                  break;

                default:
                  return CustomNoTransition(builder: (context) => SplashScreen(), settings: settings);
                  break;
              }
            }
        )
    );
  }, onError: (error, stackTrace) {

    // Whenever an error occurs, call the `_reportError` function. This sends
    // to Sentry depending on the environment.
    final MessageStream errorStream = GetIt.instance<MessageStream>();
    errorStream.reportError(error, stackTrace);

    //Report to Dev console
    print('### UNHANDLED ERROR: $error ###');
    print(stackTrace);

    // This captures errors reported by the Flutter framework.
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.dumpErrorToConsole(details);
      Zone.current.handleUncaughtError(details.exception, details.stack);
    };
  });
}

///
/// Purges existing singletons and sets up new copies.
///
void setupDependencies() {

  GetIt.instance.reset();
  GetIt.instance.registerSingleton<AuthUtils>(new AuthUtils());
  GetIt.instance.registerSingleton<MessageStream>(new MessageStream());
  GetIt.instance.registerSingleton<DatabaseUtils>(new DatabaseUtils());
  GetIt.instance.registerSingleton<TicketProvider>(new TicketProvider());
  GetIt.instance.registerSingleton<EventProvider>(new EventProvider());
  GetIt.instance.registerSingleton<VenueProvider>(new VenueProvider());
  GetIt.instance.registerSingleton<AttendeeProvider>(new AttendeeProvider());

}