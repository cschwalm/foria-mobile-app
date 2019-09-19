
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:foria/utils/configuration.dart';

import 'main.dart';

void main(){
  Configuration.setEnvironment(Environment.PROD);
  mainDelegate();

  // This captures errors reported by the Flutter framework.
  FlutterError.onError = (FlutterErrorDetails details) {
    Zone.current.handleUncaughtError(details.exception, details.stack);
  };
}