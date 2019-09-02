
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foria/providers/ticket_provider.dart';
import 'package:foria/providers/scan_processor.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:mockito/mockito.dart';


class MockBarcode extends Mock implements Barcode {}
class MockTicketProvider extends Mock implements TicketProvider {}
class MockRedemptionResult extends Mock implements RedemptionResult {}

void main() {

  final MockBarcode mockBarcode = new MockBarcode();
  final List<MockBarcode> barcodes = [];
  final TicketProvider ticketProvider = new MockTicketProvider();

  final String ticketConfigName = 'test';
  final Ticket ticket = new Ticket();
  ticket.ticketTypeConfig = new TicketTypeConfig();
  ticket.ticketTypeConfig.name = ticketConfigName;

  setUp((){
    barcodes.add(mockBarcode);
  });

  testWidgets('Non-foria QR scan test', (WidgetTester tester) async {

    final ScanProcessor scanProcessor = new ScanProcessor();

    when(mockBarcode.displayValue).thenReturn('non-foria barcode');

    ScanUIResult actual = await scanProcessor.ticketCheck(barcodes);

    scanProcessor.dispose();

    ScanUIResult expected = ScanUIResult(isValid: false, title: barcodeInvalid, subtitle: barcodeInvalidInfo);

    expect(actual.isValid,equals(expected.isValid));
    expect(actual.title, equals(expected.title));
    expect(actual.subtitle, equals(expected.subtitle));


  });

  testWidgets('Expired Foria OTP scan test', (WidgetTester tester) async {

    debugPrint(ticket.toString());

    final ScanProcessor scanProcessor = new ScanProcessor();
    final MockRedemptionResult redemptionResult = new MockRedemptionResult();

    String barcodeText = '{"ticket_id":"a10b4e38-45e8-45a4-b482-aef5fd3dd344","ticket_otp":"469029"}';
    Map<String, dynamic> jsonMap = jsonDecode(barcodeText);
    RedemptionRequest request = RedemptionRequest.fromJson(jsonMap);

    when(redemptionResult.status).thenAnswer((_) => 'DENY');
    when(redemptionResult.ticket).thenAnswer((_) => ticket);

    scanProcessor.ticketProvider = ticketProvider;

    when(mockBarcode.displayValue).thenReturn(barcodeText);

    when(ticketProvider.redeemTicket(request)).thenAnswer((_) async => redemptionResult);

    ScanUIResult actual = await scanProcessor.ticketCheck(barcodes);

    scanProcessor.dispose();

    ScanUIResult expected = ScanUIResult(isValid: false, title: passInvalid, subtitle: passInvalidInfo);

    expect(actual.isValid,equals(expected.isValid));
    expect(actual.title, equals(expected.title));
    expect(actual.subtitle, equals(expected.subtitle));

  });

  testWidgets('Valid Foria pass scan test', (WidgetTester tester) async {

    debugPrint(ticket.toString());

    final ScanProcessor scanProcessor = new ScanProcessor();
    final MockRedemptionResult redemptionResult = new MockRedemptionResult();

    String barcodeText = '{"ticket_id":"a10b4e38-45e8-45a4-b482-aef5fd3dd344","ticket_otp":"469029"}';
    Map<String, dynamic> jsonMap = jsonDecode(barcodeText);
    RedemptionRequest request = RedemptionRequest.fromJson(jsonMap);

    when(redemptionResult.status).thenAnswer((_) => 'ALLOW');
    when(redemptionResult.ticket).thenAnswer((_) => ticket);

    scanProcessor.ticketProvider = ticketProvider;

    when(mockBarcode.displayValue).thenReturn(barcodeText);

    when(ticketProvider.redeemTicket(request)).thenAnswer((_) async => redemptionResult);

    ScanUIResult actual = await scanProcessor.ticketCheck(barcodes);

    scanProcessor.dispose();

    ScanUIResult expected = ScanUIResult(isValid: true, title: ticketConfigName, subtitle: passValid);

    expect(actual.isValid,equals(expected.isValid));
    expect(actual.title, equals(expected.title));
    expect(actual.subtitle, equals(expected.subtitle));

  });

}
