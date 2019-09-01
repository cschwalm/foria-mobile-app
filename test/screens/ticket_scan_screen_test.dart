

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foria/MLtest.dart';

void main() {

  testWidgets('ML test', (WidgetTester tester) async {

    await tester.pumpWidget(MaterialApp(home:Test()));


    expect(find.text('second widget'), findsOneWidget);

  });

}