import 'package:flutter_test/flutter_test.dart';
import 'package:foria/providers/attendee_provider.dart';
import 'package:foria_flutter_client/api.dart';

void main() {

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
}