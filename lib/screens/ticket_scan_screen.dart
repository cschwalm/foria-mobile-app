import 'dart:async';
import 'dart:convert';

import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:flutter_camera_ml_vision/flutter_camera_ml_vision.dart';
import 'package:foria/providers/ticket_provider.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:wakelock/wakelock.dart';

///
/// Screen is shown in venue flow to redeem user tickets. Scanning is enabled as soon as
/// this widget is mounted.
///
class TicketScanScreen extends StatefulWidget {
  static const routeName = '/venue-scan-screen';

  @override
  _TicketScanScreenState createState() => _TicketScanScreenState();
}

class _TicketScanScreenState extends State<TicketScanScreen> {
  final TicketProvider _ticketProvider = new TicketProvider();
  final Duration _clearDuration = Duration(seconds: 6);
  final Duration _snackBarDuration = Duration(seconds: 10);

  bool _imageCaptured = false;
  String _ticketTypeName;
  ScanResult _scanResult;
  Timer _resetTimer;

  BuildContext _scaffoldContext;

  @override
  void dispose() {
    if (_resetTimer != null) {
      _resetTimer.cancel();
      _resetTimer = null;
    }
    Wakelock.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isBarcodeValid;
    Widget snackBarContent;

    // The following line will enable the Android and iOS wakelock.
    Wakelock.enable();

    final BarcodeDetectorOptions opts = BarcodeDetectorOptions(
      barcodeFormats: BarcodeFormat.qrCode
    );

    if (_scanResult != null) {
      Scaffold.of(_scaffoldContext).removeCurrentSnackBar();
      if (_scanResult == ScanResult.ALLOW){
        isBarcodeValid = true;
        snackBarContent = Text(_ticketTypeName);
      } else if (_scanResult == ScanResult.DENY){
        isBarcodeValid = false;
        snackBarContent = _snackBarContent(passInvalid, passInvalidInfo);
      } else {
        isBarcodeValid = false;
        snackBarContent = _snackBarContent(barcodeInvalid, barcodeInvalidInfo);
      }
      _showSnackBar(isBarcodeValid,snackBarContent);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(scanToRedeemTitle),
        backgroundColor: Theme
            .of(context)
            .primaryColorDark,
      ),
      body: Builder(
        builder: (BuildContext context) {
          _scaffoldContext = context;
          return SafeArea(
              child: Column(
                children: <Widget>[
                  Expanded(
                      child: CameraMlVision<List<Barcode>>(
                        detector: FirebaseVision
                            .instance
                            .barcodeDetector(opts)
                            .detectInImage,
                        onResult: (List<Barcode> barcodes) {
                          if (!mounted || _imageCaptured || barcodes.isEmpty) {
                            return;
                          }
                          _redeemTicket(barcodes.first);
                        },
                      ),
                  ),
                ],
              ),
          );
        },
      ),
    );
  }

  Widget _snackBarContent(String title, String subtitle) {
    return Column(
      children: <Widget>[
        Text(title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        SizedBox(height: 3,),
        Text(subtitle)
      ],
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
    );
  }

  ///
  /// Prompts a snackbar to pop up upon a scan. It will show for 10 seconds or until
  /// removeCurrentSnackBar() is called.
  ///
  /// Upon a scan, removeCurrentSnackBar() should be called before _showSnackBar(). This
  /// allows the new scan result to pop up immediately.
  ///
  void _showSnackBar(bool isValid, Widget content) {
    Scaffold.of(_scaffoldContext).showSnackBar(SnackBar(
      duration: _snackBarDuration,
      behavior: SnackBarBehavior.fixed,
      backgroundColor: Colors.transparent,
      elevation: 0,
      content: ScannerSnackBar(isValid: isValid, content: content),
    ));
  }

  ///
  /// Attempts to redeem the user ticket and resets for scanning.
  /// The three UI flows that can happen are ticket ALLOW, DENY, or ERROR.
  ///
  /// A ticket can only be redeemed once. The next attempt will result in DENY.
  ///
  Future<void> _redeemTicket(final Barcode barcode) async {

    final String barcodeText = barcode.displayValue;
    debugPrint('Scanned barcode text: $barcodeText');
    _imageCaptured = true;

    if (barcodeText == null) {
      setState(() {
        _imageCaptured = false;
        return;
      });
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

    setState(() {
      _ticketTypeName = redemptionResult.ticket.ticketTypeConfig.name;
      if (redemptionResult.status == 'ALLOW') {
        _scanResult = ScanResult.ALLOW;
      } else {
        _scanResult = ScanResult.DENY;
      }
    });

    debugPrint('Barcode processed.');
    _resetTimer = Timer.periodic(_clearDuration, _resetView);
  }

  ///
  /// Clears ticket ticket after set amount of time.
  ///
  void _resetView(Timer timer) async {

    setState(() {
      _imageCaptured = false;
      _scanResult = null;
      _ticketTypeName = null;
    });
    debugPrint('Ticket scan data cleared.');
    timer.cancel();
  }

  ///
  /// Sets error widget and starts reset timer if invalid data was scanned.
  ///
  void _setErrorState() {
    setState(() {
      _scanResult = ScanResult.ERROR;
    });
    debugPrint('Failed to parse barcode.');
    _resetTimer = Timer.periodic(_clearDuration, _resetView);
  }
}

enum ScanResult { ALLOW, DENY, ERROR }

///
/// The snack bar pop up action is managed by _showSnackBar(). This provides the
/// content for the popup.
///
class ScannerSnackBar extends StatelessWidget {

  final bool isValid;
  final Widget content;

  ScannerSnackBar({
    @required this.isValid,
    @required this.content
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isValid ? Colors.green : Colors.red,
      width: double.infinity,
      height: 100,
      child: Row(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Icon(
              isValid ? Icons.check : Icons.close,
              size: 40,
            ),
          ),
          Expanded(
            child: content,
          )
        ],
      ),
    );
  }
}
