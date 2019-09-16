import 'dart:async';

import 'package:flutter/cupertino.dart';

///
/// Struct containing relevant error data to display.
///
class ErrorMessage {

  final String _title;
  final String _body;

  ErrorMessage(this._title, this._body);

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

  StreamController<ErrorMessage> _streamController;

  ErrorStream() {
    _streamController = new StreamController<ErrorMessage>.broadcast();
  }

  /// Exposes steam to listen to.
  Stream<ErrorMessage> get stream => _streamController.stream;

  ///
  /// Use this method when an operation fails and you want to display an error to the user.
  /// Ensure that the stream has a subscriber.
  ///
  void announceError(ErrorMessage errorMessage) {

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
}