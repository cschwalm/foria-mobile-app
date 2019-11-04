import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/utils/auth_utils.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria/widgets/primary_button.dart';
import 'package:get_it/get_it.dart';

class Login extends StatelessWidget {
  static const routeName = '/login';
  final AuthUtils _authUtils = GetIt.instance<AuthUtils>();
  static const String loginScaffoldKey = 'login_scaffold_key';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: Key(loginScaffoldKey),
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 50),
          child: Column(
            children: <Widget>[
              Expanded(
                  child: Image.asset(
                'assets/images/foria-logo.png',
                width: 200,
              )),
              PrimaryButton(
                text: loginRegister,
                minSize: 70,
                onPress: () {
                  _authUtils.webLogin(context);
                },
              ),
            ],
          ),
        ));
  }
}
