
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/utils/constants.dart';
import 'package:foria/utils/strings.dart';

class ErrorTryAgainText extends StatelessWidget {

  final Function function;

  ErrorTryAgainText(this.function);

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
                Text(textOops,
                  style: Theme.of(context).textTheme.title,
                  textAlign: TextAlign.center,),
                sizedBoxH3,
                GestureDetector(
                  child: Text(tryAgain,
                    style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: constPrimaryColor),
                    textAlign: TextAlign.center,
                  ),
                  onTap: function,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
