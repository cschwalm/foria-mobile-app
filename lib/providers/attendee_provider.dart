import 'package:flutter/foundation.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria_flutter_client/api.dart';

///
/// Attendee Provider allows the AttendeeListScreen to be updated immediately following a manual redemption.
/// setAttendeeList should be call every time the AttendeeListScreen is refreshed
///
class AttendeeProvider extends ChangeNotifier {

  List<Attendee> _attendeeList;

  List<Attendee> get attendeeList => List.unmodifiable(_attendeeList);

  ///
  /// This should be called after the network call to manually redeem a ticket
  /// Updates the local AttendeeList
  ///
  void markAttendeeRedeemed (final Attendee attendee) {

    Attendee foundAttendee = _attendeeList.firstWhere((a) => a.ticketId == attendee.ticketId);
    foundAttendee.ticket.status = ticketStatusRedeemed;
    debugPrint('Attendee statuse changed to ${attendee.ticket.status}');
    notifyListeners();
  }

  ///
  /// Sets the AttendeeList
  ///
  void setAttendeeList (final List<Attendee> aList) {

    _attendeeList = aList;
    notifyListeners();
  }
}