import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foria/providers/ticket_provider.dart';
import 'package:foria/utils/auth_utils.dart';
import 'package:foria/utils/database_utils.dart';
import 'package:foria/utils/message_stream.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';

import '../screens/selected_event_screen_test.dart';

class MockDatabaseUtils extends Mock implements DatabaseUtils {}
class MockEventApi extends Mock implements EventApi {}
class MockTicketApi extends Mock implements TicketApi {}
class MockUserApi extends Mock implements UserApi {}
class MockMessageStream extends Mock implements MessageStream {}
class MockAuthUtils extends Mock implements AuthUtils {}

void main() {

  final _channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final MessageStream messageStream = new MockMessageStream();
  final DatabaseUtils databaseUtils = new MockDatabaseUtils();

  GetIt.instance.registerSingleton<AuthUtils>(new MockAuthUtils());
  GetIt.instance.registerSingleton<MessageStream>(messageStream);
  GetIt.instance.registerSingleton<DatabaseUtils>(databaseUtils);

  final TicketProvider ticketProvider = new TicketProvider();

  setUp(() {

    when(mockStream.listen((_) => null)).thenAnswer((_) => null);

    _channel.setMockMethodCallHandler((MethodCall methodCall) async {

      if (methodCall.method == 'read') {
        return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJleHAiOjIxNDc0ODM2NDd9.VUQXSfm9-Ub7V6-jz_ytNa-eV-TCw4M72XPneUR2ILU";
      }

      return null;
    });
  });

  tearDown(() {
    _channel.setMockMethodCallHandler(null);
  });

  test("test activateTickets", () async {

    final EventApi eventApi = new MockEventApi();
    final TicketApi ticketApi = new MockTicketApi();
    final UserApi userApi = new MockUserApi();

    ticketProvider.eventApi = eventApi;
    ticketProvider.ticketApi = ticketApi;
    ticketProvider.userApi = userApi;

    List<Ticket> tickets = _buildFakeTickets();

    Ticket activeTicketMock = new Ticket();
    activeTicketMock.id = Random.secure().nextInt(5).toString();
    activeTicketMock.status = 'ACTIVE';
    activeTicketMock.eventId = tickets[0].eventId;

    ActivationResult activationResultMock = new ActivationResult();
    activationResultMock.ticket = activeTicketMock;
    activationResultMock.ticketSecret = "TEST_SECRET";

    Event eventMock = new Event();
    eventMock.id = tickets[0].eventId;
    eventMock.name = "Test Event";

    Event eventMock1 = new Event();
    eventMock1.id = tickets[1].eventId;
    eventMock1.name = "Test Event 2";

    when(userApi.getTickets()).thenAnswer((_) async => tickets);

    when(eventApi.getEvent(tickets[0].eventId)).thenAnswer((_) async => eventMock);
    when(eventApi.getEvent(tickets[1].eventId)).thenAnswer((_) async => eventMock1);

    when(ticketApi.activateTicket(any)).thenAnswer((_) async => activationResultMock);
    when(databaseUtils.storeTicketSecret(activeTicketMock.eventId, activationResultMock.ticketSecret)).thenAnswer((_) async => null);
    when(databaseUtils.getTicketSecret(any)).thenAnswer((_) async => activationResultMock.ticketSecret);

    //Mock load data
    await ticketProvider.loadUserDataFromNetwork();

    final List<Ticket> actual = ticketProvider.userTicketList.toList();
    for (Ticket ticket in actual) {
      expect(ticket.status, equals('ACTIVE'));
    }

    expect(actual.length, equals(3));
  });

  test("test fetchEventById from network", () async {

    final EventApi eventApi = new MockEventApi();
    ticketProvider.eventApi = eventApi;

      String testEventId = "12345";

      Event eventMock = new Event();
      eventMock.id = testEventId;
      eventMock.name = "Test Event";

      when(eventApi.getEvent(testEventId)).thenAnswer((_) async => eventMock);

      Event actual = await ticketProvider.fetchEventByIdViaNetwork(testEventId);
      expect(actual, anything);
      expect(actual.id, equals(testEventId));
      expect(actual.name, equals(eventMock.name));
  });

  test("test fetchEventById with loadFromDatabase", () async {

    final EventApi eventApi = new MockEventApi();
    ticketProvider.eventApi = eventApi;

    String testEventId = "12345";

    Event eventMock = new Event();
    eventMock.id = testEventId;
    eventMock.name = "Test Event";

    when(databaseUtils.getEvent(testEventId)).thenAnswer((_) async => eventMock);

    Event actual = await ticketProvider.fetchEventByIdViaDatabase(testEventId);
    expect(actual, anything);
    expect(actual.id, equals(testEventId));
    expect(actual.name, equals(eventMock.name));

    verifyZeroInteractions(eventApi);
  });

  test("test getUserTickets from network", () async {

    final EventApi eventApi = new MockEventApi();
    final UserApi userApi = new MockUserApi();

    ticketProvider.eventApi = eventApi;
    ticketProvider.userApi = userApi;

    List<Ticket> tickets = _buildFakeTickets();

    Event eventMock = new Event();
    eventMock.id = tickets.first.eventId ;
    eventMock.name = "Test Event";

    Event eventMock1 = new Event();
    eventMock1.id = tickets.first.eventId;
    eventMock1.name = "Test Event 2";

    when(userApi.getTickets()).thenAnswer((_) async => tickets);

    when(eventApi.getEvent(tickets[0].eventId)).thenAnswer((_) async => eventMock);
    when(eventApi.getEvent(tickets[1].eventId)).thenAnswer((_) async => eventMock1);

    await ticketProvider.loadUserDataFromNetwork();
    List<Ticket> actual = ticketProvider.userTicketList.toList();

    expect(actual.length, equals(tickets.length));
  });

  test("test getUserTickets with loadFromDatabase", () async {

    final EventApi eventApi = new MockEventApi();
    ticketProvider.eventApi = eventApi;

    List<Ticket> tickets = _buildFakeTickets();

    Event eventMock = new Event();
    eventMock.id = tickets[0].eventId;
    eventMock.name = "Test Event";

    Event eventMock1 = new Event();
    eventMock1.id = tickets[1].eventId;
    eventMock1.name = "Test Event 2";

    when(databaseUtils.getAllTickets()).thenAnswer((_) async => tickets.toSet());
    when(databaseUtils.getEvent(tickets[0].eventId)).thenAnswer((_) async => eventMock);
    when(databaseUtils.getEvent(tickets[1].eventId)).thenAnswer((_) async => eventMock1);

    await ticketProvider.loadUserDataFromLocalDatabase();
    List<Ticket> actual = ticketProvider.userTicketList.toList();

    expect(actual.length, equals(tickets.length));
    verifyZeroInteractions(eventApi);
  });

  test("test getTicketsForEventId", () async {

    final EventApi eventApi = new MockEventApi();
    final UserApi userApi = new MockUserApi();

    ticketProvider.eventApi = eventApi;
    ticketProvider.userApi = userApi;

    List<Ticket> tickets = _buildFakeTickets();

    Event eventMock = new Event();
    eventMock.id = tickets[0].eventId;
    eventMock.name = "Test Event";

    Event eventMock1 = new Event();
    eventMock1.id = tickets[1].eventId;
    eventMock1.name = "Test Event 2";

    when(userApi.getTickets()).thenAnswer((_) async => tickets);

    when(eventApi.getEvent(tickets[0].eventId)).thenAnswer((_) async => eventMock);
    when(eventApi.getEvent(tickets[1].eventId)).thenAnswer((_) async => eventMock1);

    await ticketProvider.loadUserDataFromNetwork();
    Set<Ticket> actual = ticketProvider.getTicketsForEventId(tickets[0].eventId);

    expect(actual.length, equals(1));
  });
}

///
/// Builds fake tickets for mocking in tests.
///
List<Ticket> _buildFakeTickets() {

  String testTicketId = "12345";
  String testIdTicket2 = "111111";
  String testIdTicket3 = "333333";
  String testHash = '28f8ceb3b46cc0fad2dc0729ecb4e240f0160b2d3fb9f2269ad8f85c2914f5eca119fafab8e575e93f3b7a15a195599cd1e0c3fe2c901f73d152150044a46654';

  String testEventId = "55555";
  String testEventId2 = "99999";

  Ticket ticketMock = new Ticket();
  ticketMock.id = testTicketId;
  ticketMock.eventId = testEventId;
  ticketMock.status = 'ACTIVE';
  ticketMock.secretHash = testHash;

  Ticket ticketMock2 = new Ticket();
  ticketMock2.id = testIdTicket2;
  ticketMock2.eventId = testEventId2;
  ticketMock2.status = 'ISSUED';
  ticketMock2.secretHash = testHash;

  Ticket ticketMock3 = new Ticket();
  ticketMock3.id = testIdTicket3;
  ticketMock3.eventId = testEventId2;
  ticketMock3.status = 'ISSUED';
  ticketMock3.secretHash = testHash;

  List<Ticket> tickets = List<Ticket>();
  tickets.add(ticketMock);
  tickets.add(ticketMock2);
  tickets.add(ticketMock3);

  return tickets;
}