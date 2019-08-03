import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foria/providers/ticket_provider.dart';
import 'package:foria/screens/home.dart';
import 'package:foria/tabs/my_passes_tab.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:mockito/mockito.dart';


class MockTicketProvider extends Mock implements TicketProvider {}

final String _ticketId = "12345-1234-1234-12345";
final String _userId = "12345-222-222-2222";
final String _eventName = 'TestEvent';

void main() {

  final TicketProvider ticketProviderMock = new MockTicketProvider();

  setUp(() {

    List<Ticket> tickets = _generateFakeTickets();
    List<Event> events = _generateFakeEvents();
    when(ticketProviderMock.userTicketList).thenReturn(UnmodifiableListView(tickets));
    when(ticketProviderMock.eventList).thenReturn(UnmodifiableListView(events));
    when(ticketProviderMock.fetchUserTickets()).thenAnswer( (_) async { return; });

//thenReturn(new Future<void>())
  });

  testWidgets('myPassesTab contains one event in list', (WidgetTester tester) async {

    await tester.pumpWidget(MaterialApp(
      home: Tabs(ticketProviderMock),
    ));

    await tester.pumpAndSettle();

    expect(find.byType(Card), findsNWidgets(_generateFakeTickets().length));
    expect(find.byType(MissingTicket), findsNothing);
  });

  testWidgets('myPassesTab contains no events in list', (WidgetTester tester) async {

    when(ticketProviderMock.eventList).thenReturn(UnmodifiableListView(new List()));

    await tester.pumpWidget(MaterialApp(
      home: Tabs(ticketProviderMock),
    ));

    await tester.pumpAndSettle();

    final gFinder = find.descendant(of: find.byType(MissingTicket), matching: find.byType(GestureDetector));

    expect(find.byType(Card), findsNothing);
    expect(gFinder, findsOneWidget);
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

    Address testAddress = new Address();
    testAddress.city = 'San Francisco';
    testAddress.country = 'USA';
    testAddress.state = 'CA';
    testAddress.zip = '94123';

    Event event = new Event();
    event.address = testAddress;
    event.name = _eventName;
    event.id = 'TestEvent$i';
    event.description = 'test description';
    event.time = DateTime.now();
    event.imageUrl = 'foriatickets.com/img/large-square-logo';

    events.add(event);
  }

  return events;
}