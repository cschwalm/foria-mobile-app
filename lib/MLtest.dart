import 'dart:async';
import 'dart:convert';

import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:flutter_camera_ml_vision/flutter_camera_ml_vision.dart';
import 'package:foria/providers/ticket_provider.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:wakelock/wakelock.dart';


import 'package:flutter/material.dart';
import 'package:flutter_camera_ml_vision/flutter_camera_ml_vision.dart';

class Test extends StatelessWidget {
  @override
  Widget build(BuildContext context) {



    final BarcodeDetectorOptions opts = BarcodeDetectorOptions(
        barcodeFormats: BarcodeFormat.qrCode
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('title'),
        backgroundColor: Theme
            .of(context)
            .primaryColorDark,
      ),
      body: Builder(
        builder: (BuildContext context) {
//          _scaffoldContext = context;
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
                        return;
                    },
                  ),
                ),
                Text('second widget')
              ],
            ),
          );
        },
      ),
    );
  }
}
