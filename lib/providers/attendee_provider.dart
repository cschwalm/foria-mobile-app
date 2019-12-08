import 'package:flutter/foundation.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria_flutter_client/api.dart';

///
/// Attendee Provider allows the AttendeeListScreen to be updated immediately following a manual redemption.
/// setAttendeeList should be call every time the AttendeeListScreen is refreshed
///
class AttendeeProvider extends ChangeNotifier {

  List<Attendee> _attendeeList;

  List<Attendee> get attendeeList => _sortAttendeeList();

  ///
  /// This should be called after the network call to manually redeem a ticket
  /// Updates the local AttendeeList
  ///
  void markAttendeeRedeemed(final Attendee attendee) {

    Attendee foundAttendee = _attendeeList.firstWhere((a) => a.ticketId == attendee.ticketId);
    foundAttendee.ticket.status = ticketStatusRedeemed;
    debugPrint('Attendee status changed to ${attendee.ticket.status} for ticketId: ${attendee.ticket.id}');
    notifyListeners();
  }

  ///
  /// Sets the AttendeeList
  ///
  void setAttendeeList(final List<Attendee> aList) {

    _attendeeList = aList;
    notifyListeners();
  }

  ///
  /// Sort the list by last name and then first name.
  /// Tie breaker is ticketID.
  ///
  /// Returns a not mutable list.
  ///
  List<Attendee> _sortAttendeeList() {

    _attendeeList.sort( (a, b) {

      if (a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase()) != 0) {
        return a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase());
      }

      if (a.firstName.compareTo(b.firstName) != 0) {
        return a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase());
      }

      return a.ticketId.compareTo(b.ticketId);
    });

    return List.unmodifiable(_attendeeList);
  }
}