import 'package:flutter_test/flutter_test.dart';
import 'package:foria/providers/attendee_provider.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria_flutter_client/api.dart';

void main() {

  TestWidgetsFlutterBinding.ensureInitialized();

  AttendeeProvider _attendeeProvider = new AttendeeProvider();

  test("test markAttendeeRedeemed", () async {

    List<Attendee> list = new List<Attendee>();

    Attendee attendeeMock = new Attendee();
    attendeeMock.userId = 'user_id';
    attendeeMock.firstName = 'John';
    attendeeMock.lastName = 'Smith';
    attendeeMock.ticket = new Ticket();
    attendeeMock.ticket.id = '123456';
    attendeeMock.ticket.status = 'ACTIVE';
    list.add(attendeeMock);

    _attendeeProvider.setAttendeeList(list);

    _attendeeProvider.markAttendeeRedeemed(attendeeMock);

    expect(list[0].ticket.status, equals('REDEEMED'));
  });

  test('Attendee search for Joe finds one item', () async {
    final List<Attendee> attendees = _fakeAttendeeList();
    List<Attendee> result;

    result = _attendeeProvider.filterAttendees(attendees, "Joe");

    expect(result.length,1);
  });

  test('Attendee search for joe finds one item', () async {
    final List<Attendee> attendees = _fakeAttendeeList();
    List<Attendee> result;

    result = _attendeeProvider.filterAttendees(attendees, "joe");

    expect(result.length,1);
  });

  test('Attendee search for billy finds one item', () async {
    final List<Attendee> attendees = _fakeAttendeeList();
    List<Attendee> result;

    result = _attendeeProvider.filterAttendees(attendees, "billy");

    expect(result.length,1);
  });

  test('Attendee search for Corbin finds 8 item', () async {
    final List<Attendee> attendees = _fakeAttendeeList();
    List<Attendee> result;

    result = _attendeeProvider.filterAttendees(attendees, "corbin");

    expect(result.length,8);
  });
}

///
/// Generates mock list of 10 attendees with all active tickets with different attendee names
///
List<Attendee> _fakeAttendeeList() {
  List<Attendee> attendees = new List<Attendee>();

  for (int i = 0; i < 10; i++) {
    Attendee a = new Attendee();
    a.ticketId = i.toString();
    a.userId = i.toString();
    a.firstName = 'firstName' + i.toString();
    a.ticket = new Ticket();
    a.ticket.status = ticketStatusActive;
    a.ticket.ticketTypeConfig = new TicketTypeConfig();
    a.ticket.ticketTypeConfig.name = 'name';

    if (i == 0) {
      a.lastName = 'Joe';
    } else if (i == 2) {
      a.lastName = 'billy';
    } else {
      a.lastName = 'Corbin';
    }

    attendees.add(a);
  }

  return attendees;
}