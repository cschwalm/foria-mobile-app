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

  TestWidgetsFlutterBinding.ensureInitialized();

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

    when(userApi.getTickets()).thenAnswer((_) async => tickets);

    when(eventApi.getEvent(tickets[0].eventId)).thenAnswer((_) async => _buildFakeEvents()[0]);
    when(eventApi.getEvent(tickets[1].eventId)).thenAnswer((_) async => _buildFakeEvents()[1]);
    when(eventApi.getEvent(tickets[2].eventId)).thenAnswer((_) async => _buildFakeEvents()[2]);
    when(eventApi.getEvent(tickets[3].eventId)).thenAnswer((_) async => _buildFakeEvents()[3]);


    when(ticketApi.activateTicket(any)).thenAnswer((_) async => activationResultMock);
    when(databaseUtils.storeTicketSecret(activeTicketMock.eventId, activationResultMock.ticketSecret)).thenAnswer((_) async => null);
    when(databaseUtils.getTicketSecret(any)).thenAnswer((_) async => activationResultMock.ticketSecret);

    //Mock load data
    await ticketProvider.loadUserDataFromNetwork();

    final List<Ticket> actual = ticketProvider.userTicketList.toList();
    for (Ticket ticket in actual) {
      expect(ticket.status, equals('ACTIVE'));
    }

    expect(actual.length, equals(4));
  });

  test("test fetchEventById from network", () async {

    final EventApi eventApi = new MockEventApi();
    ticketProvider.eventApi = eventApi;

    Event eventMock = _buildFakeEvents()[0];
    String testEventId = eventMock.id;

    when(eventApi.getEvent(testEventId)).thenAnswer((_) async => _buildFakeEvents()[0]);

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

    // list of tickets that are all active. Ticket activation is tested separately
    List<Ticket> tickets = new List<Ticket>();
    tickets.add(_buildFakeTickets()[0]);
    tickets.add(_buildFakeTickets()[0]);

    when(userApi.getTickets()).thenAnswer((_) async => tickets);

    when(eventApi.getEvent(tickets[0].eventId)).thenAnswer((_) async => _buildFakeEvents()[0]);
    when(eventApi.getEvent(tickets[1].eventId)).thenAnswer((_) async => _buildFakeEvents()[1]);


    await ticketProvider.loadUserDataFromNetwork();
    List<Ticket> actual = ticketProvider.userTicketList.toList();

    expect(actual.length, equals(tickets.length));
  });

  test("test getUserTickets with loadFromDatabase", () async {

    final EventApi eventApi = new MockEventApi();
    ticketProvider.eventApi = eventApi;

    List<Ticket> tickets = _buildFakeTickets();

    when(databaseUtils.getAllTickets()).thenAnswer((_) async => tickets.toSet());
    when(databaseUtils.getEvent(tickets[0].eventId)).thenAnswer((_) async => _buildFakeEvents()[0]);
    when(databaseUtils.getEvent(tickets[1].eventId)).thenAnswer((_) async => _buildFakeEvents()[1]);
    when(databaseUtils.getEvent(tickets[2].eventId)).thenAnswer((_) async => _buildFakeEvents()[2]);
    when(databaseUtils.getEvent(tickets[3].eventId)).thenAnswer((_) async => _buildFakeEvents()[3]);

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

    List<Ticket> tickets = new List<Ticket>();
    tickets.add(_buildFakeTickets()[0]);
    tickets.add(_buildFakeTickets()[1]);

    when(userApi.getTickets()).thenAnswer((_) async => tickets);

    when(eventApi.getEvent(tickets[0].eventId)).thenAnswer((_) async => _buildFakeEvents()[0]);
    when(eventApi.getEvent(tickets[1].eventId)).thenAnswer((_) async => _buildFakeEvents()[1]);

    await ticketProvider.loadUserDataFromNetwork();
    Set<Ticket> actual = ticketProvider.getTicketsForEventId(tickets[0].eventId);

    expect(actual.length, equals(1));
  });

  test("test markTicketManualRedeemed", () async {

    List<Ticket> tickets = new List<Ticket>();
    tickets.add(_buildFakeTickets()[0]);

    Ticket mockTicket = _buildFakeTickets()[0];
    mockTicket.status = 'REDEEMED';

    final TicketApi ticketApi = new MockTicketApi();
    ticketProvider.ticketApi = ticketApi;

    when(ticketApi.manualRedeemTicket(tickets[0].id)).thenAnswer((_) async => mockTicket);

    Ticket actual = await ticketProvider.manualRedeemTicket(tickets[0].id);

    expect(actual, isNotNull);
    expect(actual.status, equals('REDEEMED'));
  });
}

///
/// Builds 4 mock tickets with for loop
/// Event ID equals the position in ticket list (matches event list IDs)
///
List<Ticket> _buildFakeTickets() {
  List<Ticket> tickets = List<Ticket>();

  String testHash = '28f8ceb3b46cc0fad2dc0729ecb4e240f0160b2d3fb9f2269ad8f85c2914f5eca119fafab8e575e93f3b7a15a195599cd1e0c3fe2c901f73d152150044a46654';
  final String _ticketId = "12345-1234-1234-12345";
  final String _userId = "12345-222-222-2222";

  for (int i = 0; i < 4; i++) {
    Ticket ticketMock = new Ticket();
    ticketMock.secretHash = testHash;
    ticketMock.eventId = i.toString();
    ticketMock.id = _ticketId;
    ticketMock.issuedDate = DateTime.now().toIso8601String();
    ticketMock.ownerId = _userId;
    ticketMock.purchaserId = _userId;
    ticketMock.ticketTypeConfig = TicketTypeConfig();
    ticketMock.ticketTypeConfig.name = 'test';
    if (i <= 1 ) {
      ticketMock.status = 'ACTIVE';
    } else {
      ticketMock.status = 'ISSUED';
    }

    tickets.add(ticketMock);
  }

  return tickets;
}

///
/// Generates 4 mock events with for loop
/// Event ID equals the position in event list (matches ticket list IDs)
///
List<Event> _buildFakeEvents() {
  List<Event> events = new List<Event>();

  for (int i = 0; i < 4; i++) {
    TicketTypeConfig exampleTier = new TicketTypeConfig();
    exampleTier.price = '1.00';
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
    event.id = i.toString();
    event.description = 'test description';
    event.startTime = DateTime.now();
    event.imageUrl = 'https://foriatickets.com/img/demo/draft-cover-photo.jpg';
    event.ticketTypeConfig = new List<TicketTypeConfig>();
    event.ticketTypeConfig.add(exampleTier);

    events.add(event);
  }

  return events;
}