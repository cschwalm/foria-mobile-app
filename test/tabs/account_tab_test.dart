import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foria/tabs/account_tab.dart';
import 'package:foria/utils/auth_utils.dart';
import 'package:foria/utils/configuration.dart';
import 'package:foria/utils/message_stream.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';

class MockAuthUtils extends Mock implements AuthUtils {}
class MockMessageStream extends Mock implements MessageStream {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final MessageStream messageStream = new MockMessageStream();
  final AuthUtils authUtils = new MockAuthUtils();

  GetIt.instance.registerSingleton<MessageStream>(messageStream);
  GetIt.instance.registerSingleton<AuthUtils>(authUtils);
  Configuration.setEnvironment(Environment.STAGING);

  testWidgets('Test account info renders', (WidgetTester tester) async {

    final User mockUser = new User();
    mockUser.firstName = 'Jonny';
    mockUser.lastName = 'Appleseed';
    mockUser.email = 'j.appleseed@test.com';
    when(authUtils.user).thenAnswer((_) async => mockUser);

    await tester.pumpWidget(MaterialApp(
      home: AccountTab(),
    ));

    await tester.pumpAndSettle();
    expect(find.text(mockUser.firstName + ' ' + mockUser.lastName), findsOneWidget);
    expect(find.text(mockUser.email), findsOneWidget);
  });

  testWidgets('Test null check for account info', (WidgetTester tester) async {

    when(authUtils.user).thenAnswer((_) async => null);

    await tester.pumpWidget(MaterialApp(
      home: AccountTab(),
    ));

    await tester.pumpAndSettle();
    expect(find.text('FAQ'), findsOneWidget);
  });
}