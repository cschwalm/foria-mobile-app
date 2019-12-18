import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foria/providers/event_provider.dart';
import 'package:foria/tabs/explore_events_tab.dart';
import 'package:foria/utils/auth_utils.dart';
import 'package:foria/utils/configuration.dart';
import 'package:foria/utils/message_stream.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria/widgets/no_events_column.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';

class MockAuthUtils extends Mock implements AuthUtils {}
class MockEventProvider extends Mock implements EventProvider {}
class MockMessageStream extends Mock implements MessageStream {}

void main() {

  TestWidgetsFlutterBinding.ensureInitialized();

  final MessageStream messageStream = new MockMessageStream();
  final AuthUtils authUtils = new MockAuthUtils();
  final MockEventProvider eventProviderMock = new MockEventProvider();

  GetIt.instance.registerSingleton<MessageStream>(messageStream);
  GetIt.instance.registerSingleton<AuthUtils>(authUtils);
  GetIt.instance.registerSingleton<EventProvider>(eventProviderMock);
  Configuration.setEnvironment(Environment.STAGING);

  testWidgets('ExploreEventsTab displays EventList with \$2.00 PriceSticker', (WidgetTester tester) async {
    final List<Event> events = _fakeEventWithTierPrice();

    when(eventProviderMock.events).thenReturn(UnmodifiableListView(events));
    when(eventProviderMock.getAllEvents()).thenAnswer((_) async => events);

    await tester.pumpWidget(MaterialApp(
      home: ExploreEventsTab(),
    ));

    await tester.pumpAndSettle();

    expect(find.byType(PublicEventList), findsOneWidget);
    expect(find.text('\$2.00'), findsOneWidget);
  });
  
  testWidgets('ExploreEventsTab displays EventList with Sold Out PriceSticker', (WidgetTester tester) async {
    final List<Event> events = _fakeEventSoldOut();

    when(eventProviderMock.events).thenReturn(UnmodifiableListView(events));
    when(eventProviderMock.getAllEvents()).thenAnswer((_) async => events);

    await tester.pumpWidget(MaterialApp(
      home: ExploreEventsTab(),
    ));

    await tester.pumpAndSettle();

    expect(find.byType(PublicEventList), findsOneWidget);
    expect(find.text(textSoldOut), findsOneWidget);
  });

  testWidgets('ExploreEventsTab displays NoEventsColumn when no events are in list', (WidgetTester tester) async {

    when(eventProviderMock.events).thenReturn(UnmodifiableListView(new List<Event>()));
    when(eventProviderMock.getAllEvents()).thenAnswer((_) async => new List<Event>());

    await tester.pumpWidget(MaterialApp(
      home: ExploreEventsTab(),
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