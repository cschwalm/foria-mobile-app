import 'package:flutter/material.dart';
import 'package:foria/utils/strings.dart';

///
/// Shown if events API returned no results.
///
class NoEventsColumn extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: <Widget>[
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(noEventsAvailable,
                  style: Theme.of(context).textTheme.title,
                  textAlign: TextAlign.center,),
              ],
            ),
          )
        ],
      ),
    );
  }
}