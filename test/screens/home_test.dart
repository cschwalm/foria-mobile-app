import 'package:flutter_test/flutter_test.dart';
import 'package:foria/providers/event_provider.dart';
import 'package:foria/screens/home.dart';
import 'package:foria/utils/auth_utils.dart';
import 'package:foria/utils/configuration.dart';
import 'package:foria/utils/message_stream.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';

class MockAuthUtils extends Mock implements AuthUtils {}
class MockMessageStream extends Mock implements MessageStream {}
class MockEventProvider extends Mock implements EventProvider {}

void main() {

  TestWidgetsFlutterBinding.ensureInitialized();

  final MessageStream messageStream = new MockMessageStream();
  final MockEventProvider eventProviderMock = new MockEventProvider();
  final AuthUtils authUtils = new MockAuthUtils();

  GetIt.instance.registerSingleton<MessageStream>(messageStream);
  GetIt.instance.registerSingleton<AuthUtils>(authUtils);
  GetIt.instance.registerSingleton<EventProvider>(eventProviderMock);
  Configuration.setEnvironment(Environment.STAGING);

  test('Venue tab doesnt get built when user does not have venue access', () async {

    TabsState tabsState = new TabsState();
    when(authUtils.isVenue).thenReturn(false);
    tabsState.venueAccessCheck();

    // do something to wait for 2 seconds
    await Future.delayed(const Duration(milliseconds: 100), (){});

    expect(tabsState.allTabs.length, equals(3));
  });

  test('Venue tab gets built when user does have venue access', () async {

    TabsState tabsState = new TabsState();
    when(authUtils.isVenue).thenReturn(true);
    tabsState.venueAccessCheck();

    // do something to wait for 2 seconds
    await Future.delayed(const Duration(milliseconds: 100), (){});

    expect(tabsState.allTabs.length, equals(4));
  });
}