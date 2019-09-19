import 'dart:async';
import 'dart:convert';

import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:foria/providers/ticket_provider.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:get_it/get_it.dart';

import 'constants.dart';

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

  final Duration _duplicateBarcodeDuration = Duration(seconds: 6);
  final TicketProvider _ticketProvider = GetIt.instance<TicketProvider>();

  bool _isScannerShutdown = false;
  bool _isDuplicateBarcodeTimerRunning = false;
  String _ticketTypeName;
  String _previousBarcodeText;
  ScanResult _scanResult;
  Timer _scannerShutdownTimer;
  Timer _duplicateBarcodeTimer;

  void dispose() {

    if (_scannerShutdownTimer != null) {
      _scannerShutdownTimer.cancel();
      _scannerShutdownTimer = null;
    }
    if (_duplicateBarcodeTimer != null) {
      _duplicateBarcodeTimer.cancel();
      _duplicateBarcodeTimer = null;
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

    if(barcodeText == _previousBarcodeText && _isDuplicateBarcodeTimerRunning) {
      _isScannerShutdown = false;
      return;
    } else if(barcodeText == _previousBarcodeText){
      _isDuplicateBarcodeTimerRunning = true;
      _duplicateBarcodeTimer = Timer.periodic(_duplicateBarcodeDuration, _clearPreviousBarcodeText);
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

    _previousBarcodeText = barcodeText;
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
  /// If a barcode is scanned multiple times, the UI should not continually
  /// update until the duplicatedBarcodeTimer is completed. Once the timer is complete,
  /// this enables the UI to show a new result for the same barcode
  ///
  ///
  void _clearPreviousBarcodeText (Timer timer) {

    _previousBarcodeText = null;
    _isDuplicateBarcodeTimerRunning = false;
    debugPrint('Previous barcode text cleared.');
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