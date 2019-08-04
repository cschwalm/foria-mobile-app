import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foria/providers/ticket_provider.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:mockito/mockito.dart';

class MockEventApi extends Mock implements EventApi {}
class MockUserApi extends Mock implements UserApi {}

void main() {

  const _channel = const MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final eventApi = MockEventApi();
  final userApi = MockUserApi();
  final TicketProvider ticketProvider = new TicketProvider();

  setUp(() {

    ticketProvider.eventApi = eventApi;
    ticketProvider.userApi = userApi;

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

      String testEventId = "12345";

      Event eventMock = new Event();
      eventMock.id = testEventId;
      eventMock.name = "Test Event";

      when(eventApi.getEvent(testEventId)).thenAnswer((_) async => eventMock);

      Event actual = await ticketProvider.fetchEventById(testEventId);
      expect(actual, anything);
      expect(actual.id, equals(testEventId));
      expect(actual.name, equals(eventMock.name));
  });

  test("test getUserTickets", () async {

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

    await ticketProvider.fetchUserTickets();
    List<Ticket> actual = ticketProvider.userTicketList.toList();

    expect(actual.length, equals(2));
  });

  test("test getTicketsForEventId", () async {

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

    await ticketProvider.fetchUserTickets();
    Set<Ticket> actual = ticketProvider.getTicketsForEventId(testEventId);

    expect(actual.length, equals(1));
  });
}