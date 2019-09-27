import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foria/providers/event_provider.dart';
import 'package:foria/tabs/explore_events_tab.dart';
import 'package:foria/utils/auth_utils.dart';
import 'package:foria/utils/configuration.dart';
import 'package:foria/utils/message_stream.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';

class MockAuthUtils extends Mock implements AuthUtils {}
class MockEventProvider extends Mock implements EventProvider {}
class MockMessageStream extends Mock implements MessageStream {}

void main() {

  final MessageStream messageStream = new MockMessageStream();
  final AuthUtils authUtils = new MockAuthUtils();
  final MockEventProvider eventProviderMock = new MockEventProvider();

  GetIt.instance.registerSingleton<MessageStream>(messageStream);
  GetIt.instance.registerSingleton<AuthUtils>(authUtils);
  GetIt.instance.registerSingleton<EventProvider>(eventProviderMock);
  Configuration.setEnvironment(Environment.STAGING);

  setUp(() {

    final List<Event> events = _generateFakeEvents();

    when(eventProviderMock.events).thenReturn(UnmodifiableListView(events));
    when(eventProviderMock.getAllEvents()).thenAnswer((_) async => events);
  });

  testWidgets('myPassesTab contains event cards', (WidgetTester tester) async {

    await tester.pumpWidget(MaterialApp(
      home: ExploreEventsTab(),
    ));

    await tester.pumpAndSettle();

    expect(find.byType(EventList), findsOneWidget);
  });

  testWidgets('myPassesTab contains no events in list', (WidgetTester tester) async {

    when(eventProviderMock.events).thenReturn(UnmodifiableListView(new List<Event>()));
    when(eventProviderMock.getAllEvents()).thenAnswer((_) async => new List<Event>());

    await tester.pumpWidget(MaterialApp(
      home: ExploreEventsTab(),
    ));

    await tester.pumpAndSettle();

    expect(find.byType(NoEvent), findsOneWidget);
  });
}

///
/// Generates mock events for use.
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
    event.name = 'Test Event $i';
    event.id = 'TestEvent $i';
    event.description = 'test description';
    event.startTime = DateTime.now();
    event.imageUrl = null;
//    event.ticketTypeConfig = null;

    events.add(event);
  }

  return events;
}