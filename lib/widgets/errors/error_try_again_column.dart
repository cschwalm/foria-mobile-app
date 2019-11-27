
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/utils/constants.dart';
import 'package:foria/utils/strings.dart';

class ErrorTryAgainColumn extends StatefulWidget {

  final Function function;

  ErrorTryAgainColumn(this.function);

  @override
  _ErrorTryAgainColumnState createState() => _ErrorTryAgainColumnState();
}

class _ErrorTryAgainColumnState extends State<ErrorTryAgainColumn> {

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {

    if(_isLoading) {
      return Center(child: CupertinoActivityIndicator());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Center(
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
                    onTap: () async {

                      setState(() {
                        _isLoading = true;
                      });

                      await widget.function();

                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    },
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
