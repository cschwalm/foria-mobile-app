import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foria/providers/selected_ticket_provider.dart';
import 'package:foria/screens/selected_event_screen.dart';
import 'package:foria/utils/message_stream.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';

class MockSelectedTicketProvider extends Mock implements SelectedTicketProvider {}
class MockMessageStream extends Mock implements MessageStream {}
class MockStream extends Mock implements Stream<ForiaNotification> {}

final SelectedTicketProvider selectedTicketProviderMock = new MockSelectedTicketProvider();
final MessageStream messageStreamMock = new MockMessageStream();
final MockStream mockStream = new MockStream();

void main() {

  final MessageStream messageStream = new MockMessageStream();
  GetIt.instance.registerSingleton<MessageStream>(messageStream);

  setUp(() {
    when(messageStream.stream).thenAnswer((_) => mockStream);
    when(mockStream.listen((_) => null)).thenAnswer((_) => null);

    List<Ticket> tickets = _generateFakeTickets();
    when(selectedTicketProviderMock.eventTickets).thenReturn(UnmodifiableListView(tickets));
    when(selectedTicketProviderMock.event).thenReturn(_generateFakeEvents()[0]);
    when(selectedTicketProviderMock.getBarcodeText(argThat(anything))).thenAnswer((_) => "test");
  });

  testWidgets('selectedEventScreen containes proper event name', (WidgetTester tester) async {

    final List<Event> events = _generateFakeEvents();
    final List<Ticket> tickets = _generateFakeTickets();

    await tester.pumpWidget(MaterialApp(
        home: SelectedEventScreen(selectedTicketProviderMock)
    ));
    await tester.pumpAndSettle();

    final String nameOfFirstEventCardExpected = events[0].name;
    final String typeOfPassExpected = tickets[0].ticketTypeConfig.name;
    final String venueAddrName = events[0].address.venueName;

    expect(find.byType(PassBody), findsOneWidget);
    expect(find.text(nameOfFirstEventCardExpected), findsNWidgets(2)); //Currently set to 2 because partial of the next card is on screen.
    expect(find.text(typeOfPassExpected), findsOneWidget);
    expect(find.text(venueAddrName), findsNWidgets(2));
  });
}

///
/// Generates mock tickets for use in TicketProvider
///
List<Ticket> _generateFakeTickets() {
  List<Ticket> tickets = new List<Ticket>();

  final String _ticketId = "12345-1234-1234-12345";
  final String _userId = "12345-222-222-2222";

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
    ticket.ticketTypeConfig.name = "General Admission  #$i";

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
    testAddress.venueName = "Test Venue Name #$i";
    testAddress.city = 'San Francisco';
    testAddress.country = 'USA';
    testAddress.state = 'CA';
    testAddress.zip = '94123';

    Event event = new Event();
    event.address = testAddress;
    event.name = "Test Event #$i";
    event.id = 'Test ID #$i';
    event.description = 'test description';
    event.startTime = DateTime.now();
    event.imageUrl = 'foriatickets.com/img/large-square-logo';

    List<TicketTypeConfig> ticketTypeConfigList = new List();
    TicketTypeConfig ticketTypeConfig = new TicketTypeConfig();
    ticketTypeConfig.id = "1234";
    ticketTypeConfig.name = "General Admission #$i";
    event.ticketTypeConfig = ticketTypeConfigList;

    events.add(event);
  }

  return events;
}
