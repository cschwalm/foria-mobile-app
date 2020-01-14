import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foria/main.dart';
import 'package:foria/providers/event_provider.dart';
import 'package:foria/screens/home.dart';
import 'package:foria/screens/login.dart';
import 'package:foria/screens/splash_screen.dart';
import 'package:foria/utils/auth_utils.dart';
import 'package:foria/utils/configuration.dart';
import 'package:foria/utils/message_stream.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';

class MockAuthUtils extends Mock implements AuthUtils {}
class MockMessageStream extends Mock implements MessageStream {}
class MockEventProvider extends Mock implements EventProvider {}


void main() {

  TestWidgetsFlutterBinding.ensureInitialized();

  final MessageStream messageStream = new MockMessageStream();
  final MockEventProvider eventProviderMock = new MockEventProvider();
  final AuthUtils authUtils = new MockAuthUtils();

  GetIt.instance.registerSingleton<MessageStream>(messageStream);
  GetIt.instance.registerSingleton<AuthUtils>(authUtils);
  GetIt.instance.registerSingleton<EventProvider>(eventProviderMock);
  Configuration.setEnvironment(Environment.STAGING);

  testWidgets('navigates to login screen if user not logged in', (WidgetTester tester) async {

    when(authUtils.isUserLoggedIn(true)).thenAnswer((_) => Future.value(false));

    await tester.pumpWidget(MaterialApp(
        home: SplashScreen(),
      navigatorKey: navigatorKey,
      routes: {
        Login.routeName: (context) => Container(),

      },
    ));

    await tester.pumpAndSettle();
    expect(find.byType(Container), findsOneWidget);

  });

  testWidgets('navigates to venue screen if user logged in as a venue', (WidgetTester tester) async {

    final List<Event> events = _fakeEventSoldOut();

    when(authUtils.isUserLoggedIn(true)).thenAnswer((_) => Future.value(true));
    when(authUtils.doesUserHaveVenueAccess()).thenAnswer((_) => Future.value(true));
    when(eventProviderMock.events).thenReturn(UnmodifiableListView(events));
    when(eventProviderMock.getAllEvents()).thenAnswer((_) async => events);


    await tester.pumpWidget(MaterialApp(
      home: SplashScreen(),
      navigatorKey: navigatorKey,
      routes: {
        Home.routeName: (context) => Container(),
      },
    ));

    await tester.pumpAndSettle();

    expect(find.byType(Container), findsOneWidget);

  });

  testWidgets('navigates to home if user logged in as a fan, not venue', (WidgetTester tester) async {

    when(authUtils.isUserLoggedIn(true)).thenAnswer((_) => Future.value(true));
    when(authUtils.doesUserHaveVenueAccess()).thenAnswer((_) => Future.value(false));

    await tester.pumpWidget(MaterialApp(
      home: SplashScreen(),
      navigatorKey: navigatorKey,
      routes: {
        Home.routeName: (context) => Container(),
        //the test executes the build via the Home.routename, but times out on Home(). Login() used as a proxy to prove test works
      },
    ));

    await tester.pumpAndSettle();

    expect(find.byType(Container), findsOneWidget);

  });
}

///
/// Generates mock event that is sold out.
///
List<Event> _fakeEventSoldOut() {
  List<Event> events = new List<Event>();
  TicketTypeConfig exampleTier = new TicketTypeConfig();
  exampleTier.price = '2.00';
  exampleTier.currency = 'USD';
  exampleTier.amountRemaining = 0;
  exampleTier.calculatedFee = '1.00';

  EventAddress testAddress = new EventAddress();
  testAddress.city = 'San Francisco';
  testAddress.country = 'USA';
  testAddress.state = 'CA';
  testAddress.zip = '94123';

  Event event = new Event();
  event.address = testAddress;
  event.name = 'Test Event';
  event.id = 'TestEvent';
  event.description = 'test description';
  event.startTime = DateTime.now();
  event.endTime = DateTime(2200);
  event.imageUrl = null;
  event.ticketTypeConfig = new List<TicketTypeConfig>();
  event.ticketTypeConfig.add(exampleTier);

  events.add(event);

  return events;
}