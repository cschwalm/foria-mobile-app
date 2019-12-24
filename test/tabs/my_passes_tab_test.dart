import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foria/providers/ticket_provider.dart';
import 'package:foria/tabs/my_events_tab.dart';
import 'package:foria/utils/auth_utils.dart';
import 'package:foria/utils/message_stream.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';

class MockAuthUtils extends Mock implements AuthUtils {}
class MockTicketProvider extends Mock implements TicketProvider {}
class MockMessageStream extends Mock implements MessageStream {}

final String _eventName = 'TestEvent';

void main() {

  TestWidgetsFlutterBinding.ensureInitialized();

  final MessageStream messageStream = new MockMessageStream();
  final AuthUtils authUtils = new MockAuthUtils();
  final TicketProvider ticketProviderMock = new MockTicketProvider();

  GetIt.instance.registerSingleton<MessageStream>(messageStream);
  GetIt.instance.registerSingleton<AuthUtils>(authUtils);
  GetIt.instance.registerSingleton<TicketProvider>(ticketProviderMock);

  setUp(() {

    final List<Event> events = _generateFakeEvents();

    when(ticketProviderMock.eventList).thenReturn(UnmodifiableListView(events));
    when(ticketProviderMock.ticketsActiveOnOtherDevice).thenReturn(false);
    when(ticketProviderMock.loadUserDataFromNetwork()).thenAnswer((_) async => null);
    when(authUtils.isUserEmailVerified()).thenAnswer((_) async => true);
  });

  testWidgets('myPassesTab contains event cards', (WidgetTester tester) async {

    await tester.pumpWidget(MaterialApp(
      home: MyEventsTab(),
    ));

    await tester.pumpAndSettle();

    expect(find.byType(MissingTicket), findsNothing);
    expect(find.byType(EmailVerificationConflict), findsNothing);
    expect(find.byType(DeviceConflict), findsNothing);
    expect(find.byType(EventCard), findsOneWidget);
    expect(find.byType(Card), findsNWidgets(_generateFakeEvents().length));
  });

  testWidgets('myPassesTab contains no events in list', (WidgetTester tester) async {

    when(ticketProviderMock.eventList).thenReturn(UnmodifiableListView(new List()));

    await tester.pumpWidget(MaterialApp(
      home: MyEventsTab(),
    ));

    await tester.pumpAndSettle();

    expect(find.byType(MissingTicket), findsOneWidget);
  });

  testWidgets('myPassesTab contains EmailVerificationConflict on not verified', (WidgetTester tester) async {

    when(authUtils.isUserEmailVerified()).thenAnswer((_) async => false );
    when(ticketProviderMock.eventList).thenReturn(UnmodifiableListView(new List()));

    await tester.pumpWidget(MaterialApp(
      home: MyEventsTab(),
    ));

    await tester.pumpAndSettle();

    expect(find.byType(EventCard), findsNothing);
    expect(find.byType(DeviceConflict), findsNothing);
    expect(find.byType(MissingTicket), findsNothing);
    expect(find.byType(EmailVerificationConflict), findsOneWidget);
  });
}

///
/// Generates mock events for use in TicketProvider
///
List<Event> _generateFakeEvents() {
  List<Event> events = new List<Event>();

  for (int i = 0; i < 3; i++) {
    EventAddress testAddress = new EventAddress();
    testAddress.city = 'San Francisco';
    testAddress.country = 'USA';
    testAddress.state = 'CA';
    testAddress.zip = '94123';

    Event event = new Event();
    event.address = testAddress;
    event.name = _eventName;
    event.id = 'TestEvent$i';
    event.description = 'test description';
    event.startTime = DateTime.now();
    event.imageUrl = null;

    events.add(event);
  }

  return events;
}