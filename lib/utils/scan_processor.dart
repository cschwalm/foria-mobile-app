import 'dart:async';
import 'dart:convert';

import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:foria/providers/ticket_provider.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria_flutter_client/api.dart';

enum ScanResult { ALLOW, DENY, ERROR }

class ScanUIResult {

  final bool isValid;
  final String title;
  final String subtitle;

  const ScanUIResult({this.isValid, this.title, this.subtitle});
}

///
/// Screen is shown in venue flow to redeem user tickets. Scanning is enabled as soon as
/// this widget is mounted.
///
class ScanProcessor {

  final Duration _clearDuration = Duration(seconds: 6);
  TicketProvider _ticketProvider = new TicketProvider();

  set ticketProvider(TicketProvider value) {
    _ticketProvider = value;
  }

  bool _imageCaptured = false;
  String _ticketTypeName;
  ScanResult _scanResult;
  Timer _resetTimer;

  void dispose() {

    if (_resetTimer != null) {
      _resetTimer.cancel();
      _resetTimer = null;
    }
  }

  ScanUIResult _buildScanUIResult() {

    if (_scanResult == null) {
      return null;
    }

    bool isValid;
    String title;
    String subtitle;

    if (_scanResult == ScanResult.ALLOW){
      isValid = true;
      title = _ticketTypeName;
      subtitle = passValid;
    } else if (_scanResult == ScanResult.DENY){
      isValid = false;
      title = passInvalid;
      subtitle = passInvalidInfo;
    } else {
      isValid = false;
      title = barcodeInvalid;
      subtitle = barcodeInvalidInfo;
    }

    return ScanUIResult(isValid: isValid, title: title, subtitle: subtitle);
  }

  ///
  /// Attempts to redeem ticket and builds a UI friendly result.
  ///
  Future<ScanUIResult> ticketCheck (final List<Barcode> barcodes) async {

    if (_imageCaptured || barcodes.isEmpty) {
      return null;
    }

    await _redeemTicket(barcodes.first);
    return _buildScanUIResult();
  }

  ///
  /// Attempts to redeem the user ticket and resets for scanning.
  /// The three UI flows that can happen are ticket ALLOW, DENY, or ERROR.
  ///
  /// A ticket can only be redeemed once. The next attempt will result in DENY.
  ///
  Future<void> _redeemTicket(final Barcode barcode) async {

    final String barcodeText = barcode.displayValue;
    _imageCaptured = true;

    if (barcodeText == null) {
      _imageCaptured = false;
      return;
    }

    RedemptionRequest request;
    try {
      final Map<String, dynamic> jsonMap = jsonDecode(barcodeText);
      request = RedemptionRequest.fromJson(jsonMap);
    } catch (ex) {
      debugPrint('Failed to parse encoded barcode model.');
      _setErrorState();
      _resetTimer = Timer.periodic(_clearDuration, _resetView);
      return;
    }

    if (request == null || request.ticketId == null || request.ticketOtp == null) {
      _setErrorState();
      _resetTimer = Timer.periodic(_clearDuration, _resetView);
      return;
    }

    RedemptionResult redemptionResult;
    try {
      redemptionResult = await _ticketProvider.redeemTicket(request);
    } catch (ex) {
      _setErrorState();
      _resetTimer = Timer.periodic(_clearDuration, _resetView);
      return;
    }

    _ticketTypeName = redemptionResult.ticket.ticketTypeConfig.name;
    if (redemptionResult.status == 'ALLOW') {
      _scanResult = ScanResult.ALLOW;
    } else {
      _scanResult = ScanResult.DENY;
    }

    debugPrint('Barcode processed.');
    _resetTimer = Timer.periodic(_clearDuration, _resetView);
  }

  ///
  /// Clears ticket ticket after set amount of time.
  ///
  void _resetView(Timer timer) async {

    _imageCaptured = false;
    _scanResult = null;
    _ticketTypeName = null;

    debugPrint('Ticket scan data cleared.');
    timer.cancel();
  }

  ///
  /// Sets error widget and starts reset timer if invalid data was scanned.
  ///
  void _setErrorState() {

    _scanResult = ScanResult.ERROR;
    debugPrint('Failed to parse barcode.');
  }
}