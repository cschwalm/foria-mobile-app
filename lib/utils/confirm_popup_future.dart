

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/utils/strings.dart';

class ConfirmPopupFuture {


  void confirmDialog ({
    @required Future<void> confirmFutureVoid,
    @required String title,
    @required String body,
    @required BuildContext context

  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        if(Platform.isIOS){
          return CupertinoAlertDialog(
            title: Text(title),
            content: Text(body),
            actions: <Widget>[
              CupertinoDialogAction(
                isDefaultAction: false,
                child: Text(textClose),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: Text(textConfirm),
                onPressed: () async {
                  await confirmFutureVoid;
                  Navigator.of(context).maybePop();
                },
              ),
            ],
          );
        } else {
          return AlertDialog(
            title: Text(ConfirmTransfer),
            content: Text(textConfirmCancelBody),
            actions: <Widget>[
              FlatButton(
                child: Text(textClose),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              FlatButton(
                child: Text(textConfirm),
                onPressed: () async {
                  await confirmFutureVoid;
                  Navigator.of(context).maybePop();
                },
              ),
            ],
          );
        }
      },
    );
  }
}
