import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foria/providers/ticket_provider.dart';
import 'package:foria/screens/home.dart';
import 'package:foria/tabs/my_passes_tab.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:mockito/mockito.dart';

class MockTicketProvider extends Mock implements TicketProvider {}

final String _eventName = 'TestEvent';

void main() {

  final TicketProvider ticketProviderMock = new MockTicketProvider();
  final _channel = const MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUp(() {

    List<Event> events = _generateFakeEvents();
    when(ticketProviderMock.eventList).thenReturn(UnmodifiableListView(events));
    when(ticketProviderMock.loadUserData()).thenAnswer( (_) async { return; });

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

  testWidgets('myPassesTab contains no events in list', (WidgetTester tester) async {

    when(ticketProviderMock.eventList).thenReturn(UnmodifiableListView(new List()));

    await tester.pumpWidget(MaterialApp(
      home: Tabs(ticketProviderMock),
    ));

    await tester.pumpAndSettle();

    final missingTicketFinder = find.descendant(of: find.byType(MissingTicket), matching: find.byType(GestureDetector));

    expect(missingTicketFinder, findsOneWidget);
  });

  testWidgets('myPassesTab contains EmailVerificationConflict on not verified', (WidgetTester tester) async {

    _channel.setMockMethodCallHandler((MethodCall methodCall) async {

      if (methodCall.method == 'read') {
        return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJleHAiOjIxNDc0ODM2NDcsImVtYWlsX3ZlcmlmaWVkIjpmYWxzZX0.AnpHCbc5CRYBnd11Kfu8cIMp0NgEp9LsZ09tkTFV9jg";
      }

      return null;
    });

    when(ticketProviderMock.eventList).thenReturn(UnmodifiableListView(new List()));

    await tester.pumpWidget(MaterialApp(
      home: Tabs(ticketProviderMock),
    ));

    await tester.pumpAndSettle();

    expect(find.byType(EventCard), findsNothing);
    expect(find.byType(DeviceConflict), findsNothing);
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
    event.imageUrl = 'foriatickets.com/img/large-square-logo';

    events.add(event);
  }

  return events;
}