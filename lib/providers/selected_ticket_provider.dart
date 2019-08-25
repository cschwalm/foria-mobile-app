import 'dart:async';
import 'dart:convert';

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

  final Duration _tick = Duration(seconds: 1);
  final Map<String, String> _barcodeTextMap = new Map<String, String>();
  final Map<String, String> _ticketSecretMap = new Map<String, String>();

  int _secondsRemaining = 0;
  Timer _timer;

  SelectedTicketProvider(this._event, this._eventTickets) {
    _refreshBarcodes(_timer);
    _timer = Timer.periodic(_tick, _refreshBarcodes);
  }

  @override
  void dispose() {

    _timer.cancel();
    super.dispose();
  }

  List<Ticket> get eventTickets => List.unmodifiable(_eventTickets);
  Event get event => _event;
  int get secondsRemaining => _secondsRemaining;

  ///
  /// Obtains barcode data if map has been filled or null if it's not ready.
  ///
  String getBarcodeText(final String ticketId) {

    if (ticketId == null) {
      return null;
    }

    return _barcodeTextMap[ticketId];
  }

  ///
  /// Helper method to obtain the ticket secret for specified ticket object.
  ///
  Future<String> _getTicketString(final Ticket ticket) async {

   if (ticket == null || ticket.id == null) {
     return null;
   }

   String ticketSecret;
   if (_ticketSecretMap.containsKey(ticket.id)) {
     ticketSecret = _ticketSecretMap[ticket.id];
   } else {
     ticketSecret = await _databaseUtils.getTicketSecret(ticket.id);
     _ticketSecretMap[ticket.id] = ticketSecret;
   }

   if (ticketSecret == null) {
     debugPrint('Failed to load ticket secret for ticketId: ${ticket.id}');
     throw Exception('Failed to load ticket secret for ticketId: ${ticket.id}');
   }

   final int otp = OTP.generateTOTPCode(
       ticketSecret, DateTime.now().millisecondsSinceEpoch, length: _otpLength, interval: _refreshInterval
   );

   RedemptionRequest redemptionRequest = new RedemptionRequest();
   redemptionRequest.ticketId = ticket.id;
   redemptionRequest.ticketOtp = otp.toString();

   return jsonEncode(redemptionRequest.toJson());
  }

  ///
  /// Every duration, the text is refreshed for the new OTP codes that are generated.
  ///
  Future<void> _refreshBarcodes(Timer timer) async {

    if (_secondsRemaining <= 0) {

      for (final Ticket ticket in _eventTickets) {

        final String barcodeText = await _getTicketString(ticket);
        _barcodeTextMap[ticket.id] = barcodeText;
        _secondsRemaining = 30;
      }
      debugPrint('${_eventTickets.length} tickets barcodes updated.');

    } else {
      _secondsRemaining--;
    }

    notifyListeners();
  }
}