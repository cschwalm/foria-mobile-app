import 'package:flutter/foundation.dart';
import 'package:foria/utils/database_utils.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:otp/otp.dart';

///
/// Data required to supply widgets with dynamic event info on the selected ticket screen.
///
class SelectedTicketProvider extends ChangeNotifier {

  final Event _event;
  final Set<Ticket> _eventTickets;
  final DatabaseUtils _databaseUtils = new DatabaseUtils();

  final int _refreshInterval = 30;
  final int _otpLength = 6;

  SelectedTicketProvider(this._event, this._eventTickets);

  List<Ticket> get eventTickets => List.unmodifiable(_eventTickets);
  Event get event => _event;

  ///
  /// Helper method to obtain the ticket secret for specified ticket object.
  ///
  Future<String> getTicketString(Ticket ticket) async {

   if (ticket == null || ticket.id == null) {
     return null;
   }

   final String ticketSecret = await _databaseUtils.getTicketSecret(ticket.id);
   if (ticketSecret == null) {
     debugPrint('Failed to load ticket secret for ticketId: ${ticket.id}');
     throw Exception('Failed to load ticket secret for ticketId: ${ticket.id}');
   }

   final int otp = OTP.generateTOTPCode(ticketSecret, DateTime.now().millisecondsSinceEpoch, length: _otpLength, interval: _refreshInterval);
   final redemptionRequest = new RedemptionRequest();
   redemptionRequest.ticketId = ticket.id;
   redemptionRequest.ticketOtp = otp.toString();

   return redemptionRequest.toJson().toString();
  }
}