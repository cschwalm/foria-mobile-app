import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';
import 'package:foria/utils/configuration.dart';

import 'main.dart';

void main(){
  Configuration.setEnvironment(Environment.STAGING);

  //Block and wait plugins until Flutter is ready.
  WidgetsFlutterBinding.ensureInitialized();

  //Disable analytics for test devices.
  final FirebaseAnalytics analytics = FirebaseAnalytics();
  analytics.setAnalyticsCollectionEnabled(false);

  mainDelegate();
}