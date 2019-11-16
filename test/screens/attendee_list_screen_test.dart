import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foria/providers/attendee_provider.dart';
import 'package:foria/providers/event_provider.dart';
import 'package:foria/providers/ticket_provider.dart';
import 'package:foria/screens/attendee_list_screen.dart';
import 'package:foria/utils/auth_utils.dart';
import 'package:foria/utils/configuration.dart';
import 'package:foria/utils/message_stream.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';

class MockAuthUtils extends Mock implements AuthUtils {}
class MockEventProvider extends Mock implements EventProvider {}
class MockAttendeeProvider extends Mock implements AttendeeProvider {}
class MockTicketProvider extends Mock implements TicketProvider {}
class MockMessageStream extends Mock implements MessageStream {}

void main() {

  final MessageStream messageStream = new MockMessageStream();
  final AuthUtils authUtils = new MockAuthUtils();
  final MockEventProvider eventProviderMock = new MockEventProvider();
  final MockTicketProvider ticketProviderMock = new MockTicketProvider();
  final MockAttendeeProvider attendeeProviderMock = new MockAttendeeProvider();

  GetIt.instance.registerSingleton<MessageStream>(messageStream);
  GetIt.instance.registerSingleton<AuthUtils>(authUtils);
  GetIt.instance.registerSingleton<EventProvider>(eventProviderMock);
  GetIt.instance.registerSingleton<TicketProvider>(ticketProviderMock);
  GetIt.instance.registerSingleton<AttendeeProvider>(attendeeProviderMock);
  Configuration.setEnvironment(Environment.STAGING);

  testWidgets('AttendeeListScren displays 10 tickets sold', (WidgetTester tester) async {
    final List<Attendee> attendees = _fakeAttendeeList();

    when(eventProviderMock.getAttendeesForEvent(argThat(anything))).thenAnswer((_) async => attendees);
    when(attendeeProviderMock.attendeeList).thenReturn(UnmodifiableListView(attendees));

    await tester.pumpWidget(MaterialApp(
      home: AttendeeListScreen('sample event id'),
    ));

    await tester.pumpAndSettle();

    expect(find.text(ticketsSold + _fakeAttendeeList().length.toString()), findsOneWidget);
    expect(find.text(_fakeAttendeeList()[0].ticket.ticketTypeConfig.name), findsWidgets);
  });

  testWidgets('AttendeeListScren empty list', (WidgetTester tester) async {
    final List<Attendee> attendees = _emptyAttendeeList();

    when(eventProviderMock.getAttendeesForEvent(argThat(anything))).thenAnswer((_) async => attendees);
    when(attendeeProviderMock.attendeeList).thenReturn(UnmodifiableListView(attendees));

    await tester.pumpWidget(MaterialApp(
      home: AttendeeListScreen('sample event id'),
    ));

    await tester.pumpAndSettle();

    expect(find.text(noAttendeesAvailable), findsOneWidget);
  });

  testWidgets('AttendeeListScren manual ticket redeem test', (WidgetTester tester) async { //TODO: remove or fix
    final List<Attendee> attendees = _fakeAttendeeList();
    final findCheckInButton = find.byType(OutlineButton);
    final Ticket testTicket = new Ticket();
    testTicket.status = ticketStatusRedeemed;

    when(eventProviderMock.getAttendeesForEvent(argThat(anything))).thenAnswer((_) async => attendees);
    when(attendeeProviderMock.attendeeList).thenReturn(UnmodifiableListView(attendees));
    when(ticketProviderMock.manualRedeemTicket(argThat(anything))).thenAnswer((_) async => testTicket);

    await tester.pumpWidget(MaterialApp(
      home: AttendeeListScreen('sample event id'),
    ));

    await tester.pumpAndSettle();

    expect(findCheckInButton, findsWidgets);

    await tester.tap(findCheckInButton);

    await tester.pumpAndSettle();

    expect(find.text('Yes'), findsWidgets);

    await tester.tap(find.text('Yes'));

    await tester.pumpAndSettle();

    expect(find.byKey(Key('redeemed attendee')), findsWidgets);
  });
}

///
/// Generates mock list of 10 attendees with all active tickets
///
List<Attendee> _fakeAttendeeList() {
  List<Attendee> attendees = new List<Attendee>();

  for (int i = 0; i < 10; i++) {
    Attendee a = new Attendee();
    a.ticketId = i.toString();
    a.userId = i.toString();
    a.lastName = 'lastName' + i.toString();
    a.firstName = 'firstName' + i.toString();
    a.ticket = new Ticket();
    a.ticket.status = ticketStatusActive;
    a.ticket.ticketTypeConfig = new TicketTypeConfig();
    a.ticket.ticketTypeConfig.name = 'name';
    attendees.add(a);
  }

  return attendees;
}

///
/// Generates mock list of attendees that is empty
///
List<Attendee> _emptyAttendeeList() {
  List<Attendee> attendees = new List<Attendee>();

  return attendees;
}