
import 'package:flutter/material.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria/widgets/primary_button.dart';

class TransferScreen extends StatelessWidget {
  final _emailController = TextEditingController();
  static const routeName = '/transfer-screen';

  void _saveEmail() {
    if (_emailController.text.isEmpty) {
      return;
    }
    //Corbin to hook up to API
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(requestTransfer),),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16,30,16,0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(enterTransferEmail,
              style: Theme.of(context).textTheme.body2,),
            SizedBox(height: 5,),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                  filled: true,
                  labelText: emailFieldText,
                  labelStyle: Theme.of(context).textTheme.body2,
                  fillColor: Color(formInputColor),
                  contentPadding: EdgeInsets.all(10.0),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                        width: 16.0, color: Colors.lightBlue.shade50),
                    borderRadius: buttonBorderRadius,
                  )),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value.isEmpty) {
                  return enterValidEmail;
                }
                return null;
              },
            ),
            SizedBox(height: 20,),
            Text(
              transferWarning,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.body2,
            ),
            SizedBox(height: 20,),
            PrimaryButton(
              text: transferConfirm,
              onPress: _saveEmail,
            ),
          ],
        ),
      ),
    );
  }
}