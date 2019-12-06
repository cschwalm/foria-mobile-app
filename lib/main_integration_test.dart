import 'dart:developer';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:foria/utils/auth_utils.dart';
import 'package:foria/utils/configuration.dart';

import 'main.dart';

void main() async {

  Configuration.setEnvironment(Environment.STAGING);

  //Disable analytics for test devices.
  final FirebaseAnalytics analytics = FirebaseAnalytics();
  analytics.setAnalyticsCollectionEnabled(false);

  log('Writing test refresh token.');
  final storage = new FlutterSecureStorage();
  await storage.write(key: AuthUtils.refreshTokenKey, value: '');
  final AuthUtils authUtils = new AuthUtils();
  await authUtils.forceTokenRefresh();

  mainDelegate();
}