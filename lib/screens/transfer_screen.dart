import 'package:flutter/material.dart';
import 'package:foria/providers/ticket_provider.dart';
import 'package:foria/utils/constants.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria/widgets/primary_button.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:get_it/get_it.dart';

///
/// Screen allows user to enter information such as email to allow transfer of a single ticket to a different user.
///
class TransferScreen extends StatelessWidget {

  final _emailController = TextEditingController();
  static const routeName = '/transfer-screen';

  ///
  /// Block and wait until transfer network call completes.
  ///
  Future<void> _transferTicket(Ticket selectedTicket, BuildContext context) async {

    final email = _emailController.text;
    final TicketProvider ticketProvider = GetIt.instance<TicketProvider>();

    if (email.isEmpty || selectedTicket == null) {
      return;
    }

    try {
      await ticketProvider.transferTicket(selectedTicket, email);
      Navigator.of(context).maybePop();
    } catch (ex) {
      //TODO: Handle error case.
    }
  }

  @override
  Widget build(BuildContext context) {
    final Ticket args = ModalRoute.of(context).settings.arguments as Ticket;

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
                  errorText: 'error1',
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
              onPress: () => _transferTicket(args, context),
            ),
          ],
        ),
      ),
    );
  }
}