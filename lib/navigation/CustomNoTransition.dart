import 'package:flutter/material.dart';

///
/// Provides no transition effect when navigation to new screen.
///
class CustomNoTransition<T> extends MaterialPageRoute<T> {
  CustomNoTransition({ WidgetBuilder builder, RouteSettings settings })
      : super(builder: builder, settings: settings);

  @override
  Widget buildTransitions(BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {

    return child;
  }
}