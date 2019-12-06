import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:foria/providers/ticket_provider.dart';
import 'package:foria/utils/database_utils.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:otp/otp.dart';

///
/// Data required to supply widgets with dynamic event info on the selected ticket screen.
///
class SelectedTicketProvider extends ChangeNotifier {

  final Event _event;

  static const int _refreshInterval = 30; //OTP_TIME_STEP
  static const int _otpLength = 6;

  final Duration _tick = Duration(seconds: 1);
  final Map<String, String> _barcodeTextMap = new Map<String, String>();
  final Map<String, String> _ticketSecretMap = new Map<String, String>();

  DatabaseUtils _databaseUtils;
  TicketProvider _ticketProvider;

  int _secondsRemaining = _refreshInterval - ( (DateTime.now().millisecondsSinceEpoch ~/ 1000) % _refreshInterval);
  Timer _timer;
  int _timeOffset = 0;

  SelectedTicketProvider(this._event, this._timeOffset) {

    _databaseUtils = GetIt.instance<DatabaseUtils>();
    _ticketProvider = GetIt.instance<TicketProvider>();

    _refreshBarcodes(null);
    _timer = Timer.periodic(_tick, _refreshBarcodes);
  }

  @override
  void dispose() {

    _timer.cancel();
    _timer = null;
    super.dispose();
  }

  List<Ticket> get eventTickets {

    final List<Ticket> tickets = List.of(_ticketProvider.getTicketsForEventId(_event.id));
    tickets.sort((ticketA, ticketB) {

      final String ticketTypeConfigA = ticketA.ticketTypeConfig.name;
      final String ticketTypeConfigB = ticketB.ticketTypeConfig.name;

      if (ticketTypeConfigA.compareTo(ticketTypeConfigB) != 0) {
        return ticketTypeConfigA.compareTo(ticketTypeConfigB);
      }

      return ticketA.id.compareTo(ticketB.id);
    });

    return List.unmodifiable(tickets);
  }

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
     log('Failed to load ticket secret for ticketId: ${ticket.id}', level: Level.WARNING.value);
     throw Exception('Failed to load ticket secret for ticketId: ${ticket.id}');
   }

   final DateTime offsetDateTime = DateTime.now().add(new Duration(milliseconds: _timeOffset));
   final int otp = OTP.generateTOTPCode(
       ticketSecret, offsetDateTime.millisecondsSinceEpoch, length: _otpLength, interval: _refreshInterval
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

    if (_ticketProvider == null) {
      return;
    }

    if (_secondsRemaining <= 0 || timer == null) {

      final Set<Ticket> tickets = _ticketProvider.getTicketsForEventId(_event.id);
      for (final Ticket ticket in tickets) {

        final String barcodeText = await _getTicketString(ticket);
        _barcodeTextMap[ticket.id] = barcodeText;

        final DateTime offsetDateTime = DateTime.now().add(new Duration(milliseconds: _timeOffset));
        _secondsRemaining = _refreshInterval - ( (offsetDateTime.millisecondsSinceEpoch ~/ 1000) % _refreshInterval);
      }
      log('${tickets.length} tickets barcodes updated.');

    } else {
      _secondsRemaining--;
    }

    notifyListeners();
  }
}