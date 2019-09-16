import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:foria/utils/configuration.dart';

import 'main.dart';

void main(){
  Configuration.setEnvironment(Environment.STAGING);

  //Disable analytics for test devices.
  final FirebaseAnalytics analytics = FirebaseAnalytics();
  analytics.setAnalyticsCollectionEnabled(false);

  mainDelegate();
}