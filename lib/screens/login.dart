import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria/utils/utils.dart';
import 'package:foria/widgets/primary_button.dart';

class Login extends StatelessWidget {

  static const routeName = '/login';

  @override
  Widget build (BuildContext context) => new Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16,0,16,50),
        child: Column(
          children: <Widget>[
            Expanded(
                child: Image.asset('assets/images/foria-logo.png', width: 200,)
            ),
            PrimaryButton(
              text: loginRegister,
              minSize: 70,
              onPress: (){
                webLogin(context);
              },),
          ],
        ),
      )
  );
}

