
import 'package:flutter/material.dart';
import 'package:foria/providers/ticket_provider.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria/widgets/primary_button.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:get_it/get_it.dart';

class TransferScreen extends StatelessWidget {

  final _emailController = TextEditingController();
  static const routeName = '/transfer-screen';
  final TicketProvider _ticketProvider = GetIt.instance<TicketProvider>();

  ///
  /// Block and wait until transfer network call completes.
  ///
  Future<void> _transferTicket(Ticket selectedTicket, BuildContext context) async {

    final email = _emailController.text;
    if (email.isEmpty) {
      return;
    }

    try {
      await _ticketProvider.transferTicket(selectedTicket, email);
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