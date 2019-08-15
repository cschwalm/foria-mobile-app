import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foria/providers/ticket_provider.dart';
import 'package:foria/utils/database_utils.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:mockito/mockito.dart';

class MockDatabaseUtils extends Mock implements DatabaseUtils {}
class MockEventApi extends Mock implements EventApi {}
class MockUserApi extends Mock implements UserApi {}

void main() {

  final _channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final DatabaseUtils databaseUtils = new MockDatabaseUtils();
  final TicketProvider ticketProvider = new TicketProvider();

  setUp(() {
    
    ticketProvider.databaseUtils = databaseUtils;

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

  test("test fetchEventById", () async {

    final EventApi eventApi = new MockEventApi();
    ticketProvider.eventApi = eventApi;

      String testEventId = "12345";

      Event eventMock = new Event();
      eventMock.id = testEventId;
      eventMock.name = "Test Event";

      when(eventApi.getEvent(testEventId)).thenAnswer((_) async => eventMock);

      Event actual = await ticketProvider.fetchEventById(testEventId, true);
      expect(actual, anything);
      expect(actual.id, equals(testEventId));
      expect(actual.name, equals(eventMock.name));
  });

  test("test fetchEventById with forceRefreshFalse", () async {

    final EventApi eventApi = new MockEventApi();
    ticketProvider.eventApi = eventApi;

    String testEventId = "12345";

    Event eventMock = new Event();
    eventMock.id = testEventId;
    eventMock.name = "Test Event";

    when(databaseUtils.getEvent(testEventId)).thenAnswer((_) async => eventMock);

    Event actual = await ticketProvider.fetchEventById(testEventId, false);
    expect(actual, anything);
    expect(actual.id, equals(testEventId));
    expect(actual.name, equals(eventMock.name));

    verifyZeroInteractions(eventApi);
  });

  test("test getUserTickets", () async {

    final EventApi eventApi = new MockEventApi();
    final UserApi userApi = new MockUserApi();

    ticketProvider.eventApi = eventApi;
    ticketProvider.userApi = userApi;

    String testId = "12345";
    String testId2 = "111111";

    String testEventId = "55555";
    String testEventId2 = "99999";

    Ticket ticketMock = new Ticket();
    ticketMock.id = testId;
    ticketMock.eventId = testEventId;

    Ticket ticketMock2 = new Ticket();
    ticketMock2.id = testId2;
    ticketMock2.eventId = testEventId2;

    List<Ticket> tickets = List<Ticket>();
    tickets.add(ticketMock);
    tickets.add(ticketMock2);

    Event eventMock = new Event();
    eventMock.id = testEventId;
    eventMock.name = "Test Event";

    Event eventMock1 = new Event();
    eventMock1.id = testEventId2;
    eventMock1.name = "Test Event 2";

    when(userApi.getTickets()).thenAnswer((_) async => tickets);

    when(eventApi.getEvent(testEventId)).thenAnswer((_) async => eventMock);
    when(eventApi.getEvent(testEventId2)).thenAnswer((_) async => eventMock1);

    await ticketProvider.loadUserData(true);
    List<Ticket> actual = ticketProvider.userTicketList.toList();

    expect(actual.length, equals(2));
  });

  test("test getUserTickets with forceRefreshFalse", () async {

    final EventApi eventApi = new MockEventApi();
    ticketProvider.eventApi = eventApi;

    String testId = "12345";
    String testId2 = "111111";

    String testEventId = "55555";
    String testEventId2 = "99999";

    Ticket ticketMock = new Ticket();
    ticketMock.id = testId;
    ticketMock.eventId = testEventId;

    Ticket ticketMock2 = new Ticket();
    ticketMock2.id = testId2;
    ticketMock2.eventId = testEventId2;

    List<Ticket> tickets = List<Ticket>();
    tickets.add(ticketMock);
    tickets.add(ticketMock2);

    Event eventMock = new Event();
    eventMock.id = testEventId;
    eventMock.name = "Test Event";

    Event eventMock1 = new Event();
    eventMock1.id = testEventId2;
    eventMock1.name = "Test Event 2";

    when(databaseUtils.getAllTickets()).thenAnswer((_) async => tickets.toSet());
    when(databaseUtils.getEvent(testEventId)).thenAnswer((_) async => eventMock);
    when(databaseUtils.getEvent(testEventId2)).thenAnswer((_) async => eventMock1);

    await ticketProvider.loadUserData(false);
    List<Ticket> actual = ticketProvider.userTicketList.toList();

    expect(actual.length, equals(2));
    verifyZeroInteractions(eventApi);
  });

  test("test getTicketsForEventId", () async {

    final EventApi eventApi = new MockEventApi();
    final UserApi userApi = new MockUserApi();

    ticketProvider.eventApi = eventApi;
    ticketProvider.userApi = userApi;

    String testId = "12345";
    String testId2 = "111111";

    String testEventId = "55555";
    String testEventId2 = "99999";

    Ticket ticketMock = new Ticket();
    ticketMock.id = testId;
    ticketMock.eventId = testEventId;

    Ticket ticketMock2 = new Ticket();
    ticketMock2.id = testId2;
    ticketMock2.eventId = testEventId2;

    List<Ticket> tickets = List<Ticket>();
    tickets.add(ticketMock);
    tickets.add(ticketMock2);

    Event eventMock = new Event();
    eventMock.id = testEventId;
    eventMock.name = "Test Event";

    Event eventMock1 = new Event();
    eventMock1.id = testEventId2;
    eventMock1.name = "Test Event 2";

    when(userApi.getTickets()).thenAnswer((_) async => tickets);

    when(eventApi.getEvent(testEventId)).thenAnswer((_) async => eventMock);
    when(eventApi.getEvent(testEventId2)).thenAnswer((_) async => eventMock1);

    await ticketProvider.loadUserData(true);
    Set<Ticket> actual = ticketProvider.getTicketsForEventId(testEventId);

    expect(actual.length, equals(1));
  });
}