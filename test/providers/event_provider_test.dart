import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foria/providers/event_provider.dart';
import 'package:foria/utils/auth_utils.dart';
import 'package:foria/utils/database_utils.dart';
import 'package:foria/utils/message_stream.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';

import '../screens/my_tickets_screen_test.dart';

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
  final EventApi eventApi = new MockEventApi();

  GetIt.instance.registerSingleton<AuthUtils>(new MockAuthUtils());
  GetIt.instance.registerSingleton<MessageStream>(messageStream);
  GetIt.instance.registerSingleton<DatabaseUtils>(databaseUtils);

  final EventProvider eventProvider = new EventProvider();

  setUp(() {

    eventProvider.eventApi = eventApi;

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

  test("event not null validation test", () async {

    bool actual = eventProvider.isValidEvent(_buildFakeEvent(_FakeEventType.NULL_EVENT));
    expect(actual, equals(false));
  });

  test("eventID not null validation test", () async {

    bool actual = eventProvider.isValidEvent(_buildFakeEvent(_FakeEventType.NULL_EVENT_ID));
    expect(actual, equals(false));
  });

  test("event startTime not null validation test", () async {

    bool actual = eventProvider.isValidEvent(_buildFakeEvent(_FakeEventType.NULL_START_TIME));
    expect(actual, equals(false));
  });

  test("event endTime validation test", () async {

    bool actual = eventProvider.isValidEvent(_buildFakeEvent(_FakeEventType.NULL_EVENT));
    expect(actual, equals(false));
  });

  test("event address is null validation test", () async {

    bool actual = eventProvider.isValidEvent(_buildFakeEvent(_FakeEventType.NULL_ADDRESS));
    expect(actual, equals(false));
  });

  test("event imageUrl validation test", () async {

    bool actual = eventProvider.isValidEvent(_buildFakeEvent(_FakeEventType.NULL_IMAGE_URL));
    expect(actual, equals(false));
  });

  test("event ticketTypeConfig is null validation test", () async {

    bool actual = eventProvider.isValidEvent(_buildFakeEvent(_FakeEventType.NULL_TICKET_TYPE_CONFIG));
    expect(actual, equals(false));
  });

  test("event ticketTypeConfig is empty validation test", () async {

    bool actual = eventProvider.isValidEvent(_buildFakeEvent(_FakeEventType.TICKET_TYPE_CONFIG_EMPTY));
    expect(actual, equals(false));
  });

  test("event price is null validation test", () async {

    bool actual = eventProvider.isValidEvent(_buildFakeEvent(_FakeEventType.NULL_PRICE));
    expect(actual, equals(false));
  });

  test("event calculatedFee is null validation test", () async {

    bool actual = eventProvider.isValidEvent(_buildFakeEvent(_FakeEventType.NULL_FEE));
    expect(actual, equals(false));
  });

  test("event currency is empty validation test", () async {

    bool actual = eventProvider.isValidEvent(_buildFakeEvent(_FakeEventType.NULL_CURRENCY));
    expect(actual, equals(false));
  });

  test("getAttendees list test", () async {

    final String eventId = '123456';
    List<Attendee> mockList = buildAttendeeList();

    when(eventApi.getAttendeesForEvent(eventId)).thenAnswer((_) async => mockList);

    List<Attendee> actual = await eventProvider.getAttendeesForEvent(eventId);
    expect(mockList.length, equals(actual.length));
  });
}

enum _FakeEventType {

  VALID_EVENT,
  NULL_EVENT,
  NULL_EVENT_ID,
  NULL_START_TIME,
  NULL_END_TIME,
  PAST_END_TIME,
  NULL_ADDRESS,
  NULL_IMAGE_URL,
  NULL_TICKET_TYPE_CONFIG,
  TICKET_TYPE_CONFIG_EMPTY,
  NULL_AMOUNT_REMAINING,
  NULL_PRICE,
  NULL_FEE,
  NULL_CURRENCY
}

///
/// Generates a mock event based on _FakeEventType
/// Designed to invalidate a specific field in an event for invalidation testing
///
Event _buildFakeEvent(_FakeEventType _fakeEventType) {
  Event validEvent = new Event();

  TicketTypeConfig validTier = new TicketTypeConfig();
  validTier.price = '1.00';
  validTier.currency = 'USD';
  validTier.amountRemaining = 1;
  validTier.calculatedFee = '1.00';

  EventAddress validAddress = new EventAddress();
  validAddress.city = 'San Francisco';
  validAddress.country = 'USA';
  validAddress.state = 'CA';
  validAddress.zip = '94123';

  validEvent.address = validAddress;
  validEvent.name = 'Test Event';
  validEvent.id = '12345';
  validEvent.description = 'test description';
  validEvent.startTime = DateTime.now();
  validEvent.endTime = DateTime(2100);
  validEvent.imageUrl = 'https://foriatickets.com/img/demo/draft-cover-photo.jpg';
  validEvent.ticketTypeConfig = new List<TicketTypeConfig>();
  validEvent.ticketTypeConfig.add(validTier);

  if(_fakeEventType == _FakeEventType.NULL_EVENT){
    Event nullEvent;
    return nullEvent;
  }
  if(_fakeEventType == _FakeEventType.NULL_EVENT_ID){
    Event nullEventId = validEvent;
    nullEventId.id = null;
    return nullEventId;
  }
  if(_fakeEventType == _FakeEventType.NULL_START_TIME){
    Event pastEndTime = validEvent;
    pastEndTime.startTime = null;
    return pastEndTime;
  }
  if(_fakeEventType == _FakeEventType.NULL_END_TIME){
    Event nullEndTime = validEvent;
    nullEndTime.endTime = null;
    return nullEndTime;
  }
  if(_fakeEventType == _FakeEventType.PAST_END_TIME){
    Event pastEndTime = validEvent;
    pastEndTime.endTime = DateTime(2000);
    return pastEndTime;
  }
  if(_fakeEventType == _FakeEventType.NULL_ADDRESS){
    Event nullAddress = validEvent;
    nullAddress.address = null;
    return nullAddress;
  }
  if(_fakeEventType == _FakeEventType.NULL_IMAGE_URL){
    Event nullImage = validEvent;
    nullImage.imageUrl = null;
    return nullImage;
  }
  if(_fakeEventType == _FakeEventType.NULL_TICKET_TYPE_CONFIG){
    Event nullTypeConfig = validEvent;
    nullTypeConfig.ticketTypeConfig = null;
    return nullTypeConfig;
  }
  if(_fakeEventType == _FakeEventType.TICKET_TYPE_CONFIG_EMPTY){
    Event emptyTypeConfig = validEvent;
    emptyTypeConfig.ticketTypeConfig = [];
    return emptyTypeConfig;
  }
  if(_fakeEventType == _FakeEventType.NULL_AMOUNT_REMAINING){
    Event invalidEvent = validEvent;
    TicketTypeConfig nullAmountRemaining = validTier;
    nullAmountRemaining.amountRemaining = null;
    invalidEvent.ticketTypeConfig.add(nullAmountRemaining);
    return invalidEvent;
  }
  if(_fakeEventType == _FakeEventType.NULL_PRICE){
    Event invalidEvent = validEvent;
    TicketTypeConfig nullPrice = validTier;
    nullPrice.price = null;
    invalidEvent.ticketTypeConfig.add(nullPrice);
    return invalidEvent;
  }
  if(_fakeEventType == _FakeEventType.NULL_FEE){
    Event invalidEvent = validEvent;
    TicketTypeConfig nullFee = validTier;
    nullFee.calculatedFee = null;
    invalidEvent.ticketTypeConfig.add(nullFee);
    return invalidEvent;
  }
  if(_fakeEventType == _FakeEventType.NULL_CURRENCY){
    Event invalidEvent = validEvent;
    TicketTypeConfig nullCurrency = validTier;
    nullCurrency.currency = null;
    invalidEvent.ticketTypeConfig.add(nullCurrency);
    return invalidEvent;
  }

  return validEvent;
}

///
/// Builds fake list of attendees with ACTIVE status for testing.
///
List<Attendee> buildAttendeeList() {

  List<Attendee> list = new List<Attendee>();

  Attendee attendeeMock = new Attendee();
  attendeeMock.userId = 'user_id';
  attendeeMock.firstName = 'John';
  attendeeMock.lastName = 'Smith';
  attendeeMock.ticketId = '123456';
  attendeeMock.ticket = new Ticket();
  attendeeMock.ticket.id = '123456';
  attendeeMock.ticket.status = 'ACTIVE';
  list.add(attendeeMock);

  return list;
}
