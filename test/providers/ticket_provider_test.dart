import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foria/providers/ticket_provider.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:mockito/mockito.dart';

class MockEventApi extends Mock implements EventApi {}

void main() {

  const _channel = const MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final eventApi = MockEventApi();
  final TicketProvider ticketProvider = new TicketProvider();

  setUp(() {

    ticketProvider.eventApi = eventApi;

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
}