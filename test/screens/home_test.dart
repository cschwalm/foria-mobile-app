import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foria/main.dart';
import 'package:foria/providers/event_provider.dart';
import 'package:foria/providers/ticket_provider.dart';
import 'package:foria/screens/home.dart';
import 'package:foria/utils/auth_utils.dart';
import 'package:foria/utils/configuration.dart';
import 'package:foria/utils/message_stream.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';

class MockAuthUtils extends Mock implements AuthUtils {}
class MockMessageStream extends Mock implements MessageStream {}
class MockEventProvider extends Mock implements EventProvider {}
class MockTicketProvider extends Mock implements TicketProvider {}

void main() {

  TestWidgetsFlutterBinding.ensureInitialized();

  final MessageStream messageStream = new MockMessageStream();
  final MockEventProvider eventProviderMock = new MockEventProvider();
  final MockTicketProvider ticketProviderMock = new MockTicketProvider();
  final AuthUtils authUtils = new MockAuthUtils();

  GetIt.instance.registerSingleton<MessageStream>(messageStream);
  GetIt.instance.registerSingleton<AuthUtils>(authUtils);
  GetIt.instance.registerSingleton<EventProvider>(eventProviderMock);
  GetIt.instance.registerSingleton<TicketProvider>(ticketProviderMock);
  Configuration.setEnvironment(Environment.STAGING);

  when(authUtils.isUserEmailVerified()).thenAnswer((_) => Future.value(true));

  test('Venue tab doesnt get built when user does not have venue access', () async {

    TabsState tabsState = new TabsState();
    when(authUtils.isVenue).thenAnswer((_) => Future.value(false));
    tabsState.venueAccessCheck();

    // do something to wait for 2 seconds
    await Future.delayed(const Duration(milliseconds: 100), (){});

    expect(tabsState.allTabs.length, equals(3));
  });

  testWidgets('Venue tab gets built when user does have venue access', (WidgetTester tester) async {

    when(authUtils.isVenue).thenAnswer((_) => Future.value(true));
    when(ticketProviderMock.loadUserDataFromNetwork()).thenAnswer((_) async => null);
    when(ticketProviderMock.loadUserDataFromLocalDatabase()).thenAnswer((_) async => null);
    when(ticketProviderMock.userTicketList).thenReturn(UnmodifiableListView<Ticket>(List()));
    when(ticketProviderMock.eventList).thenReturn(UnmodifiableListView<Event>(List()));

    await tester.pumpWidget(MaterialApp(
      home: Home(),
      navigatorKey: navigatorKey,
      routes: {
        Home.routeName: (context) => Home()
      },
    ));

    await tester.pumpAndSettle();
    expect(find.text('Scanner'), findsOneWidget);
  });
}