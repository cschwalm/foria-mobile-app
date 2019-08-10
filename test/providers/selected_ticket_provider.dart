import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foria/providers/ticket_provider.dart';
import 'package:foria/screens/home.dart';
import 'package:foria/screens/selected_ticket_screen.dart';
import 'package:foria/tabs/my_passes_tab.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/services.dart';

class MockTicketProvider extends Mock implements TicketProvider {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

final String _ticketId = "12345-1234-1234-12345";
final String _userId = "12345-222-222-2222";
final String _eventName = 'TestEvent';

void main() {
  final TicketProvider ticketProviderMock = new MockTicketProvider();
  NavigatorObserver mockObserver;
  final _channel = const MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUp(() {
    mockObserver = MockNavigatorObserver();

    List<Ticket> tickets = _generateFakeTickets();
    List<Event> events = _generateFakeEvents();
    when(ticketProviderMock.userTicketList)
        .thenReturn(UnmodifiableListView(tickets));
    when(ticketProviderMock.eventList).thenReturn(UnmodifiableListView(events));
    when(ticketProviderMock.fetchUserTickets()).thenAnswer( (_) async { return; });

    _channel.setMockMethodCallHandler((MethodCall methodCall) async {

      if (methodCall.method == 'read') {
        return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJleHAiOjIxNDc0ODM2NDcsImVtYWlsX3ZlcmlmaWVkIjp0cnVlfQ.rgvCxxhoZHs94LHV-m86mvgEZFFZK-VQc_5GZH4m1q4";
      }

      return null;
    });
  });

  testWidgets('myPassesTab contains one event in list', (WidgetTester tester) async {

    await tester.pumpWidget(MaterialApp(
      home: Tabs(ticketProviderMock),
    ));

    await tester.pumpAndSettle();

    expect(find.byType(Card), findsNWidgets(_generateFakeEvents().length));
    expect(find.byType(MissingTicket), findsNothing);
    expect(find.byType(EmailVerificationConflict), findsNothing);
  });

  testWidgets('selectedTicketScreen containes proper event name',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Tabs(ticketProviderMock),
      navigatorObservers: [mockObserver],
      routes: {
        SelectedTicketScreen.routeName: (context) => SelectedTicketScreen(),
      },
    ));

    await tester.pumpAndSettle();

    final Key keyOfFirstEventCard = Key(_generateFakeEvents()[0].id);

    final cardFinder = find.descendant(
        of: find.byType(EventCard),
        matching: find.byKey(keyOfFirstEventCard));

    await tester.tap(cardFinder);

    await tester.pumpAndSettle();

    final String nameOfFirstEventCard = _generateFakeEvents()[0].name;

    final eventNameFinder = find.descendant(
        of: find.byType(EventInfo),
        matching: find.text(nameOfFirstEventCard));

    verify(mockObserver.didPush(any, any));

    expect(find.byType(SelectedTicketScreen), findsOneWidget);

    expect(eventNameFinder, findsOneWidget);
  });
}

///
/// Generates mock tickets for use in TicketProvider
///
List<Ticket> _generateFakeTickets() {
  List<Ticket> tickets = new List<Ticket>();

  for (int i = 0; i < 3; i++) {
    Ticket ticket = new Ticket();
    ticket.eventId = _ticketId;
    ticket.id = _ticketId;
    ticket.issuedDate = DateTime.now().toIso8601String();
    ticket.ownerId = _userId;
    ticket.purchaserId = _userId;
    ticket.status = "ACTIVE";
    ticket.secretHash = "SECERT";
    ticket.ticketTypeConfig = new TicketTypeConfig();
    ticket.ticketTypeConfig.name = "General Admission";

    tickets.add(ticket);
  }

  return tickets;
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
    event.imageUrl = 'foriatickets.com/img/large-square-logo';

    events.add(event);
  }

  return events;
}
