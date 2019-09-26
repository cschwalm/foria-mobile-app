import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:foria/utils/auth_utils.dart';
import 'package:foria/utils/configuration.dart';
import 'package:foria/utils/constants.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info/package_info.dart';
import 'package:sentry/sentry.dart';

enum MessageType {
  MESSAGE,
  ERROR,
  NETWORK_ERROR
}
///
/// Struct containing relevant error data to display.
///
class ForiaNotification {

  final String _body;
  final MessageType _messageType;

  final String _title;
  dynamic _initialException;
  dynamic _stackTrace;

  ForiaNotification.error(this._messageType, this._body, this._title, this._initialException, this._stackTrace);
  ForiaNotification.message(this._messageType, this._body, this._title);

  String get body => _body;
  String get title => _title;
  MessageType get messageType => _messageType;
  dynamic get stackTrace => _stackTrace;
  dynamic get initialException => _initialException;
}

///
/// Exposes a pipeline (broadcast stream controller) that allows errors to be written and read from a single point in the application.
/// This is intended to be used as a singleton across the application.
///
/// @author Corbin Schwalm <corbin@foriatickets.com>
///
class MessageStream {

  SentryClient _sentry;
  StreamController<ForiaNotification> _streamController;

  StreamSubscription<ForiaNotification> _currentStreamSubscription;

  MessageStream() {
    _streamController = new StreamController<ForiaNotification>.broadcast();
    _setupCloudMessaging();
  }

  void addListener(void onData(ForiaNotification event)) {

    if (_currentStreamSubscription != null) {
      _currentStreamSubscription.cancel();
    }

    _currentStreamSubscription = _streamController.stream.asBroadcastStream().listen(onData);
  }

  ///
  /// Use this method to send a user a message.
  /// Ensure that the stream has a subscriber.
  ///
  void announceMessage(ForiaNotification notification) {

    if (_streamController.isPaused || _streamController.isClosed) {
      debugPrint('Failed to write message to stream. Stream is paused/closed.');
      return;
    }

    if (!_streamController.hasListener) {
      debugPrint('Failed to write message to stream. Stream has no listeners.');
      return;
    }

    _streamController.add(notification);
  }

  ///
  /// Use this method when an operation fails and you want to display an error to the user.
  /// Ensure that the stream has a subscriber.
  ///
  /// Reports error to Sentry in production.
  ///
  void announceError(ForiaNotification notification) {

    if (notification.messageType != MessageType.NETWORK_ERROR) {
      reportError(notification.initialException, notification.stackTrace);
    }

    if (_streamController.isPaused || _streamController.isClosed) {
      debugPrint('Failed to write error to error stream. Stream is paused/closed.');
      return;
    }

    if (!_streamController.hasListener) {
      debugPrint('Failed to write error to error stream. Stream has no listeners.');
      return;
    }

    _streamController.add(notification);
  }

  ///
  /// Send the Exception and Stacktrace to Sentry in Production mode.
  ///
  Future<void> reportError(dynamic error, dynamic stackTrace) async {

    if (error != null) {

      final String envLabel = Environment.STAGING == Configuration.getEnvironment() ? 'staging' : 'prodution';

      if (_sentry == null) {
        final PackageInfo packageInfo = await PackageInfo.fromPlatform();
        final buildVersion = '${packageInfo.version} - Build: ${packageInfo.buildNumber}';

        final AuthUtils authUtils = GetIt.instance<AuthUtils>();
        final user = authUtils.user;
        final User userContext = new User(id: user.id, email: user.email);
        final Event env = new Event(release: buildVersion, environment: envLabel, userContext: userContext);

        _sentry = new SentryClient(dsn: sentryDsn, environmentAttributes: env);

        _sentry.captureException(
          exception: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  ///
  /// Configures Firebase to pump messages into event stream.
  /// Obtains token and uploads it to server.
  ///
  void _setupCloudMessaging() {

    final FirebaseMessaging firebaseMessaging = FirebaseMessaging();

    firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {

        String title, body;
        if (message['notification'] != null) {
          title = message['notification']['title'];
          body = message['notification']['body'];
        } else if (message['aps'] != null) {
          title = message['aps']['alert']['title'];
          body = message['aps']['alert']['body'];
        } else {
          debugPrint('ERROR: Failed to parse notification');
          return;
        }

        print("Received push notification: $message");
        final ForiaNotification foriaNotification = new ForiaNotification.message(MessageType.MESSAGE, body, title);
        announceMessage(foriaNotification);
      },
      onLaunch: (Map<String, dynamic> message) async {
        //Do nothing.
      },
      onResume: (Map<String, dynamic> message) async {
        //Do nothing.
      },
    );
  }
}