import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/providers/ticket_provider.dart';
import 'package:foria/utils/error_stream.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria/widgets/primary_button.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:get_it/get_it.dart';

///
/// Screen allows user to enter information such as email to allow transfer of a single ticket to a different user.
///
class TransferScreen extends StatefulWidget {

  static const routeName = '/transfer-screen';

  @override
  _TransferScreenState createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {

  String _emailSubmission;
  final _form = GlobalKey<FormState>();
  final _emailCheck = r"^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$";

  ///
  /// Block and wait until transfer network call completes.
  ///
  Future<void> _transferTicket(Ticket selectedTicket, BuildContext context) async {

    final TicketProvider ticketProvider = GetIt.instance<TicketProvider>();
    final ErrorStream errorStream = GetIt.instance<ErrorStream>();
    Ticket updatedTicket;


    final isValid = _form.currentState.validate();
    if (!isValid) {
      return;
    }
    _form.currentState.save();

    if (_emailSubmission.isEmpty || selectedTicket == null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Text('Error'),
            actions: <Widget>[
              FlatButton(
                child: Text('Ok'),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            ],
          );
        },
      );
    } else {
      try {
        updatedTicket = await ticketProvider.transferTicket(selectedTicket, _emailSubmission);
        Navigator.of(context).maybePop();
        debugPrint('SUCCESSFUL TICKET TRANSFER');
        if(updatedTicket.status == ticketStatusTransferPending){
          errorStream.announceError(new ErrorMessage("", 'Transfer Pending'));
          debugPrint('TICKET is pending');
        } else {
          errorStream.announceError(new ErrorMessage("", 'Transfer Complete'));
          debugPrint('TICKET is complete');
        }
      } catch (ex) {
        errorStream.announceError(new ErrorMessage("", netConnectionError));
        debugPrint('ERROR WIRTH TICKET TRANSFER');
      }
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
            Form(
              key: _form,
              child: TextFormField(
                    decoration: InputDecoration(labelText: enterTransferEmail),
                    validator: (value) {
                      if (RegExp(_emailCheck).hasMatch(value)) {
                        return null;
                      }
                      return 'Please enter a valid email';
                    },
                    onSaved: (value) {
                      _emailSubmission = value;
                    },
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
              onPress: () => _transferTicket(args, context),
            ),
          ],
        ),
      ),
    );
  }
}