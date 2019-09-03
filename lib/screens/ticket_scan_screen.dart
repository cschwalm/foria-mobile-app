import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:flutter_camera_ml_vision/flutter_camera_ml_vision.dart';
import 'package:foria/utils/scan_processor.dart';
import 'package:foria/utils/strings.dart';
import 'package:wakelock/wakelock.dart';

class TicketScanScreen extends StatelessWidget {

  static const routeName = '/venue-scan-screen';

  @override
  Widget build(BuildContext context) {
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
          return SafeArea(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: CameraWidget(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class CameraWidget extends StatefulWidget {

  final BuildContext scaffoldContext;

  CameraWidget(this.scaffoldContext);

  @override
  _CameraWidgetState createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget> {

  final Duration _snackBarDuration = Duration(seconds: 10);

  ScanProcessor _scanProcessor;
  BarcodeDetectorOptions _opts;

  @override
  void initState() {
    _scanProcessor = new ScanProcessor();
    _opts = BarcodeDetectorOptions(
        barcodeFormats: BarcodeFormat.qrCode
    );

    // The following line will enable the Android and iOS wakelock.
    Wakelock.enable();
    super.initState();
  }

  @override
  void dispose() {
    Wakelock.disable();
    super.dispose();
    _scanProcessor.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CameraMlVision<List<Barcode>>(
      detector: FirebaseVision
          .instance
          .barcodeDetector(_opts)
          .detectInImage,
      onResult: (List<Barcode> barcodes) {
        if (!mounted) {
          return;
        }
        _scanProcessor.ticketCheck(barcodes).then((result) {
          if (result == null) {
            return;
          }
          Scaffold.of(widget.scaffoldContext).removeCurrentSnackBar();
          Scaffold.of(widget.scaffoldContext).showSnackBar(
              SnackBar(
                duration: _snackBarDuration,
                behavior: SnackBarBehavior.fixed,
                backgroundColor: Colors.transparent,
                elevation: 0,
                content: ScannerSnackBar(isValid: result.isValid, title: result.title, subtitle: result.subtitle),
              )
          );
        });
      },
    );
  }
}

///
/// The snack bar pop up action is managed by _showSnackBar(). This provides the
/// content for the popup.
///
class ScannerSnackBar extends StatelessWidget {

  final bool isValid;
  final String title;
  final String subtitle;


  ScannerSnackBar({
    @required this.isValid,
    @required this.title,
    @required this.subtitle,
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
            child: Column(
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
            ),
          )
        ],
      ),
    );
  }
}
