import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:foria/utils/auth_utils.dart';
import 'package:foria/utils/configuration.dart';
import 'package:foria/utils/constants.dart';
import 'package:foria_flutter_client/api.dart' as foriaUser;
import 'package:sentry/sentry.dart';

///
/// Struct containing relevant error data to display.
///
class ErrorMessage {

  final String _title;
  final String _body;

  dynamic initialException;
  dynamic stackTrace;

  ErrorMessage(this._title, this._body);
  ErrorMessage.error(this._title, this._body, this.initialException, this.stackTrace);

  String get body => _body;
  String get title => _title;
}

///
/// Exposes a pipeline (broadcast stream controller) that allows errors to be written and read from a single point in the application.
/// This is intended to be used as a singleton across the application.
///
/// @author Corbin Schwalm <corbin@foriatickets.com>
///
class ErrorStream {

  final SentryClient _sentry = SentryClient(dsn: sentryDsn);
  StreamController<ErrorMessage> _streamController;

  ErrorStream() {
    _streamController = new StreamController<ErrorMessage>.broadcast();

    final foriaUser.User user = AuthUtils.user;
    if (user != null) {
      final User userContext = new User(id: user.id, email: user.email);
      _sentry.userContext = userContext;
    }
  }

  /// Exposes steam to listen to.
  Stream<ErrorMessage> get stream => _streamController.stream;

  ///
  /// Use this method when an operation fails and you want to display an error to the user.
  /// Ensure that the stream has a subscriber.
  ///
  /// Reports error to Sentry in production.
  ///
  void announceError(ErrorMessage errorMessage) {

    reportError(errorMessage.initialException, errorMessage.stackTrace);

    if (_streamController.isPaused || _streamController.isClosed) {
      debugPrint('Failed to write error to error stream. Stream is paused/closed.');
      return;
    }

    if (!_streamController.hasListener) {
      debugPrint('Failed to write error to error stream. Stream has no listeners.');
      return;
    }

    _streamController.add(errorMessage);
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