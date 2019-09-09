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

  final Duration _invalidResultDisabledDuration = Duration(seconds: 6);
  TicketProvider _ticketProvider = new TicketProvider();

  set ticketProvider(TicketProvider value) {
    _ticketProvider = value;
  }

  bool _isScannerShutdown = false;
  bool _isInvalidResultDisabled = false;
  String _ticketTypeName;
  ScanResult _scanResult;
  Timer _scannerShutdownTimer;
  Timer _invalidResultDisabledTimer;

  void dispose() {

    if (_scannerShutdownTimer != null) {
      _scannerShutdownTimer.cancel();
      _scannerShutdownTimer = null;
    }
    if (_invalidResultDisabledTimer != null) {
      _invalidResultDisabledTimer.cancel();
      _invalidResultDisabledTimer = null;
    }
  }

  ScanUIResult _buildScanUIResult() {

    if (_scanResult == null) {
      return null;
    }

    _scannerShutdownTimer = Timer.periodic(scannerShutdownDuration, _restartScanner);

    bool isValid;
    String title;
    String subtitle;

    if (_scanResult == ScanResult.ALLOW){
      isValid = true;
      title = _ticketTypeName;
      subtitle = passValid;
    } else if (_isInvalidResultDisabled){
      return null;
    } else if (_scanResult == ScanResult.DENY){
      isValid = false;
      title = passInvalid;
      subtitle = passInvalidInfo;
      _isInvalidResultDisabled = true;
      _invalidResultDisabledTimer = Timer.periodic(_invalidResultDisabledDuration, _enableInvalidResultUI);
    } else {
      isValid = false;
      title = barcodeInvalid;
      subtitle = barcodeInvalidInfo;
      _isInvalidResultDisabled = true;
      _invalidResultDisabledTimer = Timer.periodic(_invalidResultDisabledDuration, _enableInvalidResultUI);
    }

    return ScanUIResult(isValid: isValid, title: title, subtitle: subtitle);
  }

  ///
  /// Attempts to redeem ticket and builds a UI friendly result.
  ///
  Future<ScanUIResult> ticketCheck (final List<Barcode> barcodes) async {

    if (_isScannerShutdown || barcodes.isEmpty) {
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
    _isScannerShutdown = true;

    if (barcodeText == null) {
      _isScannerShutdown = false;
      return;
    }

    RedemptionRequest request;
    try {
      final Map<String, dynamic> jsonMap = jsonDecode(barcodeText);
      request = RedemptionRequest.fromJson(jsonMap);
    } catch (ex) {
      debugPrint('Failed to parse encoded barcode model.');
      _setErrorState();
      return;
    }

    if (request == null || request.ticketId == null || request.ticketOtp == null) {
      _setErrorState();
      return;
    }

    RedemptionResult redemptionResult;
    try {
      redemptionResult = await _ticketProvider.redeemTicket(request);
    } catch (ex) {
      _setErrorState();
      return;
    }

    _ticketTypeName = redemptionResult.ticket.ticketTypeConfig.name;
    if (redemptionResult.status == 'ALLOW') {
      _scanResult = ScanResult.ALLOW;
    } else {
      _scanResult = ScanResult.DENY;
    }

    debugPrint('Barcode processed.');
  }

  ///
  /// Clears scan result and enables camera after set amount of time.
  ///
  void _restartScanner(Timer timer) {

    _isScannerShutdown = false;
    _scanResult = null;
    _ticketTypeName = null;

    debugPrint('Ticket scan data cleared.');
    timer.cancel();
  }

  ///
  /// Allows the UI to show invalid ticket result.
  ///
  void _enableInvalidResultUI (Timer timer) {

    _isInvalidResultDisabled = false;

    debugPrint('ticket_scan_screen UI can now show invalid results.');
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