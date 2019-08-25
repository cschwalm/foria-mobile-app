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
  final Duration _clearDuration = Duration(seconds: 3);

  bool _imageCaptured = false;
  String _ticketId;
  String _ticketTypeName;
  ScanResult _scanResult;
  Timer _resetTimer;

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

    // The following line will enable the Android and iOS wakelock.
    Wakelock.enable();

    List<Widget> children = new List<Widget>();

    Widget cameraWidget = SizedBox(
      width: MediaQuery
          .of(context)
          .size
          .width,
      child: CameraMlVision<List<Barcode>>(
        detector: FirebaseVision.instance
            .barcodeDetector()
            .detectInImage,
        onResult: (List<Barcode> barcodes) {
          if (!mounted || _imageCaptured || barcodes.isEmpty) {
            return;
          }

          _redeemTicket(barcodes.first);
        },
      ),
    );
    children.add(cameraWidget);

    if (_scanResult != null) {
      Widget resultWidget =
      TickScanResultWidget(
          _ticketId,
          _ticketTypeName,
          _scanResult
      );
      children.add(resultWidget);
    }

    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        title: Text(scanToRedeemTitle),
        backgroundColor: Theme
            .of(context)
            .primaryColorDark,
      ),
      body: SafeArea(

          child: Column(
              children: children
          )
      ),
    );
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
      return;
    }

    final Map<String, dynamic> jsonMap = jsonDecode(barcodeText);
    final RedemptionRequest request = RedemptionRequest.fromJson(jsonMap);

    RedemptionResult redemptionResult;
    try {
      redemptionResult = await _ticketProvider.redeemTicket(request);
    } catch (ex) {
      setState(() {
        _scanResult = ScanResult.ERROR;
        _ticketId = null;
        _ticketTypeName = null;
      });

      debugPrint('Failed to process barcode.');
      _resetTimer = Timer.periodic(_clearDuration, _resetView);
      return;
    }

    setState(() {

      if (redemptionResult.status == 'ALLOW') {
        _ticketId = redemptionResult.ticket.id;
        _ticketTypeName = redemptionResult.ticket.ticketTypeConfig.name;
        _scanResult = ScanResult.ALLOW;
      } else {
        _ticketId = redemptionResult.ticket.id;
        _ticketTypeName = redemptionResult.ticket.ticketTypeConfig.name;
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
      _ticketId = null;
      _ticketTypeName = null;
    });
    debugPrint('Ticket scan data cleared.');
    timer.cancel();
  }
}

enum ScanResult { ALLOW, DENY, ERROR }

///
/// Displays scan results from server.
///
class TickScanResultWidget extends StatelessWidget {

  final String ticketId;
  final String ticketTypeName;
  final ScanResult scanResult;

  TickScanResultWidget(this.ticketId, this.ticketTypeName, this.scanResult);

  @override
  Widget build(BuildContext context) {

    List<TableRow> rows = new List<TableRow>();

    TableRow ticketTypeNameRow, scanResultRow;
    if (scanResult != ScanResult.ERROR) {

      ticketTypeNameRow = new TableRow(
          children: [
            Text('Ticket Type:'),
            Text(ticketTypeName)
          ]
      );

      scanResultRow = new TableRow(
          children: [
            Text('Status'),
            Text(scanResult.toString())
          ]
      );

      rows.add(ticketTypeNameRow);
      rows.add(scanResultRow);
    } else {

      TableRow errorRow = new TableRow(
        children: [
          Text('Error Reading Ticket - Scan Again'),
        ]
      );
      rows.add(errorRow);
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(5.0, 20.0, 5.0, 20.0),
        child: Container(
          decoration: BoxDecoration(
            border: new Border.all(color: Colors.black),
            color: scanResult == ScanResult.ALLOW ? Colors.green : Colors.red,
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold
            ),
            child: Table(
              children: rows,
            ),
          )
      )
    );
  }
}
