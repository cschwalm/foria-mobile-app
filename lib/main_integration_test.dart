import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:foria/utils/auth_utils.dart';
import 'package:foria/utils/configuration.dart';

import 'main.dart';

void main() async {

  Configuration.setEnvironment(Environment.STAGING);

  //Disable analytics for test devices.
  final FirebaseAnalytics analytics = FirebaseAnalytics();
  analytics.setAnalyticsCollectionEnabled(false);

  debugPrint('Writing test refresh token.');
  final storage = new FlutterSecureStorage();
  await storage.write(key: AuthUtils.refreshTokenKey, value: 'mL9uG8N1hPCvp6dP8VxWhvr50TdTUiOFTZhuVT-ItsmYd');
  final AuthUtils authUtils = new AuthUtils();
  await authUtils.forceTokenRefresh();

  mainDelegate();
}