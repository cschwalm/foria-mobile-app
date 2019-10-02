import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foria/providers/selected_ticket_provider.dart';
import 'package:foria/providers/ticket_provider.dart';
import 'package:foria/screens/transfer_screen.dart';
import 'package:foria/utils/constants.dart';
import 'package:foria/utils/message_stream.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria/widgets/primary_button.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock/wakelock.dart';

///
/// Screen displays rotating barcodes for user to scan.
/// Barcodes cannot be generated unless tickets are active and their secrets are stored.
///
class MyTicketsScreen extends StatefulWidget {

  static const routeName = '/my-tickets-screen';
  final SelectedTicketProvider _selectedTicketProvider;

  MyTicketsScreen([this._selectedTicketProvider]);

  @override
  _MyTicketsScreenState createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {

  SelectedTicketProvider _selectedTicketProvider;

  @override
  void initState() {
    Wakelock.enable();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    final Map<String, dynamic> args = ModalRoute.of(context).settings.arguments as Map<String, dynamic>;
    if (_selectedTicketProvider == null) {
      if (args == null || args['event'] == null) {
        _selectedTicketProvider = widget._selectedTicketProvider;
      } else {
        _selectedTicketProvider = new SelectedTicketProvider(args['event']);
      }
    }

    return Scaffold(
        resizeToAvoidBottomPadding: false,
        backgroundColor: Colors.black,
        body: ChangeNotifierProvider<SelectedTicketProvider>.value(
        value: _selectedTicketProvider,
        child: PassBody(),
      ));
  }

  @override
  void dispose() {
    _selectedTicketProvider.dispose();
    Wakelock.disable();
    super.dispose();
  }
}

///
/// Creates the page view for ticket displays.
///
/// Also listens for stream updates
///
class PassBody extends StatefulWidget {

  @override
  _PassBodyState createState() => _PassBodyState();
}

class _PassBodyState extends State<PassBody> {

  @override
  void initState() {

    super.initState();
  }

  @override
  Widget build(BuildContext context) {

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

    final double viewportFraction = 0.9;
    final double width = MediaQuery.of(context).size.width;
    final double closeButtonPadding = (1-viewportFraction) * width / 2;
    final double verticalPadding = 7;

    final SelectedTicketProvider _selectedTicketProvider = Provider.of<SelectedTicketProvider>(context, listen: false);
    final int _passCount = _selectedTicketProvider.eventTickets.length;

    return SafeArea(
        child: Column(
          children: <Widget>[
            Row(
                children: <Widget>[
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: closeButtonPadding, vertical: verticalPadding),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                    ),
                    onTap: () {
                      Navigator.maybePop(context);
                    },
                  ),
                ],
              ),
            Expanded(
              child: PageView.builder(
                // store this controller in a State to save the carousel scroll position
                controller: PageController(viewportFraction: viewportFraction),
                itemCount: _passCount,
                itemBuilder: (BuildContext context, int itemIndex) {
                  return PassCard(itemIndex, _passCount);
                },
              ),
            ),
            SizedBox(height: verticalPadding,)
          ],
        ),
      );
  }
}

///
/// Shows barcode with time remaining.
///
class PassCard extends StatelessWidget {

  final int _index;
  final int _passCount;

  PassCard(this._index, this._passCount);

  @override
  Widget build(BuildContext context) {

    final SelectedTicketProvider selectedTicketProvider = Provider.of<SelectedTicketProvider>(context);

    final passNumber = _index + 1;
    final Ticket ticket = selectedTicketProvider.eventTickets.elementAt(_index);
    final String barcodeText = selectedTicketProvider.getBarcodeText(ticket.id);
    final double passRefreshHeight = 25;
    Widget barcodeContent;
    bool showTimer = false;
    List<Widget> barcodeList = List<Widget>();


    if(barcodeText == null){
      barcodeContent = Center(
        child: CupertinoActivityIndicator(),
    );
    } else if (ticket.status == ticketStatusTransferPending) {
      barcodeContent = Stack(
        children: <Widget>[
          Image.asset(
            transferPendingImage,
            width: 220,
            height: 220,
          ),
          Center(child: Text(textTransferPending),),
        ],
      );
    } else {
      showTimer = true;
      barcodeContent = QrImage(data: barcodeText);
    }

    barcodeList.add(Container(
      height: 220,
      width: 220,
      child: barcodeContent,
    ));
    barcodeList.add(SizedBox(height: 10));

    if(showTimer){
      barcodeList.add(PassRefresh(selectedTicketProvider.secondsRemaining,passRefreshHeight));
    } else {
      barcodeList.add(SizedBox(height: passRefreshHeight,));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            EventInfo(),
            SizedBox(height: 5),
            Directions(),
            Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'Pass $passNumber of $_passCount',
                          style: Theme
                              .of(context)
                              .textTheme
                              .title,
                        ),
                        SizedBox(height: 5),
                        Text(
                          ticket.ticketTypeConfig.name,
                          style: Theme
                              .of(context)
                              .textTheme
                              .title,
                        ),
                        SizedBox(height: 20),
                        Column(children: barcodeList),
                      ],
                    ),
                  ),
                )
            ),
            PassOptions(ticket)
          ],
        ),
      ),
    );
  }
}

///
/// Displays the event name, venue name and date
///
class EventInfo extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    final SelectedTicketProvider selectedTicketProvider = Provider.of<SelectedTicketProvider>(context, listen: false);

    DateTime serverStartTime = selectedTicketProvider.event.startTime;
    DateTime localDateTime = DateTime.now();
    Duration timezoneOffset = localDateTime.timeZoneOffset;
    Duration timeDiff = new Duration(hours: timezoneOffset.inHours, minutes: timezoneOffset.inMinutes % 60);
    DateTime localStartTime = serverStartTime.add(timeDiff);

    String month = dateFormatShortMonth.format(localStartTime);
    String day = localStartTime.day.toString();
    String startClockTime = dateFormatTime.format(localStartTime);

    return Container(
      color: Colors.white,
      child: Row(
        children: <Widget>[
          Stack(
            children: <Widget>[
              Image.asset(calendarImage),
              Padding(
                padding: const EdgeInsets.only(top: 17),
                child: Container(
                  height: 59,
                  width: 71,
                  alignment: Alignment.center,
                  child: Text(
                    '$month\n$day',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headline,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            width: 16,
          ),
          Expanded(
            child: Column(
              children: <Widget>[
                Text(
                  selectedTicketProvider.event.name,
                  style: Theme.of(context).textTheme.headline,
                ),
                Text(
                  selectedTicketProvider.event.address.venueName,
                  style: Theme.of(context).textTheme.body1,
                ),
                Text(
                  startClockTime,
                  style: Theme.of(context).textTheme.body1,
                ),
              ],
              crossAxisAlignment: CrossAxisAlignment.start,
            ),
          ),
        ],
      ),);
  }
}

///
/// Directions provided via google maps link
///
class Directions extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    final SelectedTicketProvider selectedTicketProvider = Provider.of<SelectedTicketProvider>(context, listen: false);
    final addr = selectedTicketProvider.event.address;

    return GestureDetector(
      child: Row(
        children: <Widget>[
          Icon(
            Icons.location_on,
            color: Theme.of(context).primaryColor,
          ),
          Text(
            directionsText,
            style: TextStyle(
                fontSize: 18, color: Theme.of(context).primaryColor),
          ),
        ],
      ),
      onTap: () async {

        final String url = googleMapsSearchUrl + Uri.encodeFull(addr.streetAddress + " " + addr.city + " " + addr.state + " " + addr.zip);

        if (await canLaunch(url)) {
          await launch(url);
        } else {
          print('Could not launch $url');
        }
      },
    );
  }
}

///
/// Countdown to pass refresh widget
///
class PassRefresh extends StatelessWidget {

  final _secondsRemaining;
  final double _height;

  PassRefresh(this._secondsRemaining,this._height);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 25,
          height: _height,
          alignment: Alignment.center,
          child: Text(
            _secondsRemaining.toString(),
            style: Theme.of(context).textTheme.body2,
          ),
        ),
        Text(
          passRefresh,
          style: Theme.of(context).textTheme.body2,
        ),
      ],
    );
  }
}

///
/// Button to initiate a transfer or to cancel a transfer.
///
/// There is a popup to confirm cancel transfer
///
class PassOptions extends StatefulWidget {

  final Ticket _selectedTicket;

  PassOptions(this._selectedTicket);

  @override
  _PassOptionsState createState() => _PassOptionsState();
}

class _PassOptionsState extends State<PassOptions> {

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    PrimaryButton button;
    Widget dialog;

    if(Platform.isIOS){
      dialog = CupertinoAlertDialog(
        title: Text(textConfirmCancel),
        content: Text(textConfirmCancelBody),
        actions: <Widget>[
          CupertinoDialogAction(
            isDefaultAction: false,
            child: Text(textClose),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(textConfirm),
            onPressed: () {
              _cancelTransfer(widget._selectedTicket);
              Navigator.of(context).maybePop();
            },
          ),
        ],
      );
    } else {
      dialog = AlertDialog(
        title: Text(textConfirmCancel),
        content: Text(textConfirmCancelBody),
        actions: <Widget>[
          FlatButton(
            child: Text(textClose),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          FlatButton(
            child: Text(textConfirm),
            onPressed: () {
              _cancelTransfer(widget._selectedTicket);
              Navigator.of(context).maybePop();
            },
          ),
        ],
      );
    }

    if (widget._selectedTicket.status == ticketStatusTransferPending) {
      button = PrimaryButton(
          text: cancelTransfer,
          isLoading: _isLoading,
          onPress: () {
            if(!_isLoading){
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return dialog;
                },
              );
            } else {
              return null;
            }
          }
      );
    } else {
      button = PrimaryButton(
        text: textTransfer,
        onPress: () {
          Navigator.of(context).pushNamed(
            TransferScreen.routeName,
            arguments: widget._selectedTicket,
          );
        },
      );
    }

    return button;
  }

  ///
  /// Block and wait until cancel transfer network call completes.
  ///
  Future<void> _cancelTransfer(Ticket _selectedTicket) async {

    final TicketProvider ticketProvider = GetIt.instance<TicketProvider>();

    setState(() {
      _isLoading = true;
    });

    try {
      await ticketProvider.cancelTicketTransfer(_selectedTicket);
    } catch (ex) {
      debugPrint('Transfer for ${_selectedTicket.id} failed');
    }

    setState(() {
      _isLoading = false;
    });
  }
}