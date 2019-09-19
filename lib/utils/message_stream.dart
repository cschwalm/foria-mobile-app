import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:foria/utils/configuration.dart';
import 'package:foria/utils/constants.dart';
import 'package:foria_flutter_client/api.dart' as foriaUser;
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
  MessageType get message => _messageType;

}

///
/// Exposes a pipeline (broadcast stream controller) that allows errors to be written and read from a single point in the application.
/// This is intended to be used as a singleton across the application.
///
/// @author Corbin Schwalm <corbin@foriatickets.com>
///
class MessageStream {

  final SentryClient _sentry = SentryClient(dsn: sentryDsn);
  StreamController<ForiaNotification> _streamController;

  MessageStream() {
    _streamController = new StreamController<ForiaNotification>.broadcast();
  }

  ///
  /// Tags user with data from Auth0
  ///
  void setUserInfo(foriaUser.User user) {

    if (user != null) {
      final User userContext = new User(id: user.id, email: user.email);
      _sentry.userContext = userContext;
    }
  }

  /// Exposes steam to listen to.
  Stream<ForiaNotification> get stream => _streamController.stream;

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

    reportError(notification._initialException, notification._stackTrace);

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

      if (Configuration.getEnvironment() != Environment.STAGING) {

        _sentry.captureException(
          exception: error,
          stackTrace: stackTrace,
        );
      }
    }
  }
}