// Imports the Flutter Driver API.
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {

  group('Foria Integration test:', () {

    FlutterDriver driver;

    // Connect to the Flutter driver before running any tests.
    setUpAll(() async {
      driver = await FlutterDriver.connect();
      sleep(Duration(seconds: 2));
    });

    // Close the connection to the driver after the tests have completed.
    tearDownAll(() async {
      if (driver != null) {
        driver.close();
      }
    });

    test('check flutter driver health', () async {
      Health health = await driver.checkHealth();
      print(health.status);
    });

    test('tap device conflict button', () async {

      final findConflictButton = find.byValueKey('device_conflict_key');

      await driver.waitFor(findConflictButton);
      await driver.tap(findConflictButton);

    });

    test('click through to myPassScreen', () async {

      final findEventCard = find.byValueKey('event_card_key0');

      await driver.waitFor(findEventCard);
      await driver.tap(findEventCard);

    });
    
    test('swipe and count passes', () async {

      final findPassList = find.byValueKey('my_passes_list');
      final findPassCardOne = find.byValueKey('pass_card_key0');
      final findPassCardTwo = find.byValueKey('pass_card_key1');
      final findPassCardThree = find.byValueKey('pass_card_key2');
      final findPassCardFour = find.byValueKey('pass_card_key3');


      await driver.waitFor(findPassCardOne);
      await driver.waitFor(findPassCardTwo);

      await driver.scrollUntilVisible(findPassList, findPassCardThree, dxScroll: -300);
      await driver.scrollUntilVisible(findPassList, findPassCardFour);


    });
  });
}