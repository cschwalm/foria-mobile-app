import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foria/providers/ticket_provider.dart';
import 'package:foria/utils/constants.dart';
import 'package:foria/utils/message_stream.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria/widgets/primary_button.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:get_it/get_it.dart';

class TransferScreen extends StatelessWidget {

  static const routeName = '/transfer-screen';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(requestTransfer),),
        body: TransferScreenBody());
  }
}


///
/// Screen allows user to enter information such as email to allow transfer of a single ticket to a different user.
///
class TransferScreenBody extends StatefulWidget {

  @override
  _TransferScreenBodyState createState() => _TransferScreenBodyState();
}

class _TransferScreenBodyState extends State<TransferScreenBody> {

  String _emailSubmission;
  final _form = GlobalKey<FormState>();
  final _emailCheck = r"^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$";
  bool _isLoading = false;


  ///
  /// Block and wait until transfer network call completes.
  ///
  Future<void> _transferTicket(Ticket selectedTicket, BuildContext context) async {

    final TicketProvider ticketProvider = GetIt.instance<TicketProvider>();
    bool isEventNowEmpty = false;

    setState(() {
      _isLoading = true;
    });
    isEventNowEmpty = await ticketProvider.transferTicket(selectedTicket, _emailSubmission);
    setState(() {
      _isLoading = false;
    });
    Navigator.pop(context, 'hello');
    Navigator.pop(context, 'hello');

    //If the last ticket for an event was transferred the MyTicketsScreen should be popped
    if(isEventNowEmpty){
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Ticket args = ModalRoute.of(context).settings.arguments as Ticket;

    final MessageStream messageStream = GetIt.instance<MessageStream>();
    messageStream.addListener((errorMessage) {
      Scaffold.of(context).showSnackBar(
          SnackBar(
            backgroundColor: snackbarColor,
            elevation: 0,
            content: FlatButton(
              child: Text(errorMessage.body),
              onPressed: () => Scaffold.of(context).hideCurrentSnackBar(),
            ),
          )
      );
    });

    return Padding(
        padding: const EdgeInsets.fromLTRB(16,30,16,0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Form(
              key: _form,
              child: TextFormField(
                    decoration: InputDecoration(labelText: enterTransferEmail),
                    validator: (value) {
                      if (RegExp(_emailCheck).hasMatch(value)) {
                        return null;
                      }
                      return enterValidEmail;
                    },
                    onSaved: (value) {
                      _emailSubmission = value;
                    },
                keyboardType: TextInputType.emailAddress,
                  ),
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
              isLoading: _isLoading,
              onPress: _isLoading ? null : () {
                final isValid = _form.currentState.validate();
                if (!isValid) {
                  return;
                }
                _form.currentState.save();
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    final String title = ConfirmTransfer;
                    final String body = ConfirmTransferBody + _emailSubmission;
                    if (Platform.isIOS) {
                      return CupertinoAlertDialog(
                        title: Text(title),
                        content: Text(body),
                        actions: <Widget>[
                          CupertinoDialogAction(
                            isDefaultAction: false,
                            child: Text(textClose),
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                          CupertinoDialogAction(
                            isDefaultAction: true,
                            child: Text(textConfirm),
                            onPressed: () async {
                              await _transferTicket(args, context);
                            },
                          ),
                        ],
                      );
                    } else {
                      return AlertDialog(
                        title: Text(ConfirmTransfer),
                        content: Text(textConfirmCancelBody),
                        actions: <Widget>[
                          FlatButton(
                            child: Text(textClose),
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                          FlatButton(
                            child: Text(textConfirm),
                            onPressed: () async {
                              await _transferTicket(args, context);
                              Navigator.of(context).maybePop();
                            },
                          ),
                        ],
                      );
                    }
                  },
                );
              },
            )
          ],
        ),
      );
  }
}