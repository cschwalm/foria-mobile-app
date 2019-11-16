import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foria/providers/venue_provider.dart';
import 'package:foria/screens/organizer_events_screen.dart';
import 'package:foria/utils/auth_utils.dart';
import 'package:foria/utils/configuration.dart';
import 'package:foria/utils/message_stream.dart';
import 'package:foria/widgets/no_events_column.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';

class MockAuthUtils extends Mock implements AuthUtils {}
class MockVenueProvider extends Mock implements VenueProvider {}
class MockMessageStream extends Mock implements MessageStream {}

void main() {

  final MessageStream messageStream = new MockMessageStream();
  final AuthUtils authUtils = new MockAuthUtils();
  final MockVenueProvider venueProviderMock = new MockVenueProvider();

  GetIt.instance.registerSingleton<MessageStream>(messageStream);
  GetIt.instance.registerSingleton<AuthUtils>(authUtils);
  GetIt.instance.registerSingleton<VenueProvider>(venueProviderMock);
  Configuration.setEnvironment(Environment.STAGING);

  testWidgets('OrganizerEventsScreen displays EventList', (WidgetTester tester) async {
    final List<Event> events = _fakeEventWithTierPrice();

    when(venueProviderMock.venueEvents).thenReturn(UnmodifiableListView(events));
    when(venueProviderMock.getAllVenuesEvents()).thenAnswer((_) async => events);

    await tester.pumpWidget(MaterialApp(
      home: OrganizerEventsScreen(),
    ));

    await tester.pumpAndSettle();

    expect(find.byType(OrganizerEventList), findsOneWidget);
  });

  testWidgets('OrganizerEventsScreen displays NoEventsColumn when no events are in list', (WidgetTester tester) async {

    when(venueProviderMock.venueEvents).thenReturn(UnmodifiableListView(new List<Event>()));
    when(venueProviderMock.getAllVenuesEvents()).thenAnswer((_) async => new List<Event>());

    await tester.pumpWidget(MaterialApp(
      home: OrganizerEventsScreen(),
    ));

    await tester.pumpAndSettle();

    expect(find.byType(NoEventsColumn), findsOneWidget);
  });
}

///
/// Generates mock event with a $2 ticket tier.
///
List<Event> _fakeEventWithTierPrice() {
  List<Event> events = new List<Event>();
  TicketTypeConfig exampleTier = new TicketTypeConfig();
  exampleTier.price = '2.00';
  exampleTier.currency = 'USD';
  exampleTier.amountRemaining = 1;
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
  event.imageUrl = null;
  event.ticketTypeConfig = new List<TicketTypeConfig>();
  event.ticketTypeConfig.add(exampleTier);

  events.add(event);

  return events;
}