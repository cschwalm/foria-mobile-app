import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/providers/selected_ticket_provider.dart';
import 'package:foria/providers/ticket_provider.dart';
import 'package:foria/utils/auth_utils.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria/widgets/contact_support.dart';
import 'package:foria/widgets/errors/simple_error.dart';
import 'package:foria/widgets/primary_button.dart';
import 'package:provider/provider.dart';

import '../screens/selected_ticket_screen.dart';

class MyPassesTab extends StatefulWidget {

  @override
  _MyPassesTabState createState() => _MyPassesTabState();
}

enum _LoadingState {

  EMAIL_VERIFY,
  LOAD_TICKETS,
  DONE
}

///
/// Contains simple state machine to handle three flows.
/// Step 1: Tab opened. Nothing has been done. We need to display loading and check email verify.
/// Step 2: Email is verified, display spinner and load tickets.
/// Step 3: Display tickets results.
///
class _MyPassesTabState extends State<MyPassesTab> with AutomaticKeepAliveClientMixin<MyPassesTab> {

  _LoadingState _currentState;
  bool _isUserEmailCheckFinished;
  bool _isTicketsLoaded;

  bool _isUserEmailVerified;

  @override
  void initState() {

    _currentState = _LoadingState.EMAIL_VERIFY;
    _isUserEmailCheckFinished = false;
    _isTicketsLoaded = false;

    _isUserEmailVerified = false;
    super.initState();
  }

  @override
  void didChangeDependencies() {

    switch (_currentState) {

      case _LoadingState.EMAIL_VERIFY:

        if (!_isUserEmailCheckFinished) {
          isUserEmailVerified().then((isEmailVerified) {
            setState(() {
              _isUserEmailCheckFinished = true;
              _isUserEmailVerified = isEmailVerified;

              //If email is verified, set next state and start the initial load.
              if (_isUserEmailVerified) {
                _isTicketsLoaded = false;
                _currentState = _LoadingState.LOAD_TICKETS;

                _loadTicketsAndSetState();
              }
            });
          });
        }

        break;

      case _LoadingState.LOAD_TICKETS:

        if (!_isTicketsLoaded) {
          _loadTicketsAndSetState();
        }
        break;

      case _LoadingState.DONE:
        break;
    }

    super.didChangeDependencies();
  }

  ///
  /// Triggers ticket load and resets spinner.
  ///
  Future<void> _loadTicketsAndSetState() async {

    //Email is verified. Load tickets and stop spinner when completed.
    TicketProvider ticketProvider = Provider.of<TicketProvider>(context);
    ticketProvider.loadUserDataFromNetwork().then((_) {
      setState(() {
        _isTicketsLoaded = true;
        _currentState = _LoadingState.DONE;
      });
    }).catchError((error) {

      print('getTickets network call failed. Loading from offline database.');
      showErrorAlert(context, ticketLoadingFailure);
      ticketProvider.loadUserDataFromLocalDatabase().then((_) {
        setState(() {
          _isTicketsLoaded = true;
          _currentState = _LoadingState.DONE;
        });
      });
    });
  }

  ///
  /// Helper function that allows ticket loading to be blocked until finishing.
  ///
  Future<void> _awaitTicketLoad() async {

    TicketProvider ticketProvider = Provider.of<TicketProvider>(context);
    try {
      await ticketProvider.loadUserDataFromNetwork();
    } catch (ex) {
      print('getTickets network call failed during manual refresh. Loading from offline database.');
      showErrorAlert(context, ticketLoadingFailure);
      await ticketProvider.loadUserDataFromLocalDatabase();
    }
  }

  @override
  Widget build(BuildContext context) {

    final _eventData = Provider.of<TicketProvider>(context, listen: false);

    if ( (_currentState == _LoadingState.EMAIL_VERIFY && !_isUserEmailCheckFinished) || _currentState == _LoadingState.LOAD_TICKETS) {
      return CupertinoActivityIndicator(
        radius: 15,
      );
    }

    if (_currentState == _LoadingState.EMAIL_VERIFY) {
      return EmailVerificationConflict(this.emailVerifyCallback);
    }

    if (_eventData.eventList.length <= 0) {
      return MissingTicket();
    }

    super.build(context);
    return RefreshIndicator(
        onRefresh: _awaitTicketLoad,
        child: EventCard()
    );
  }

  void emailVerifyCallback() async {

    await forceTokenRefresh();
    bool isEmailVerified = await isUserEmailVerified();

      if (isEmailVerified) {
        setState(() {
          _isUserEmailCheckFinished = true;
          _isUserEmailVerified = true;
          _currentState = _LoadingState.LOAD_TICKETS;

          _loadTicketsAndSetState();
        });
      }
  }

  @override
  bool get wantKeepAlive => true;
}

class EventCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final _eventData = Provider.of<TicketProvider>(context, listen: true);
    

    return ListView.builder(
        itemCount: _eventData.eventList.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: GestureDetector(
              key: Key(_eventData.eventList[index].id),
              onTap: () {
                Navigator.of(context).pushNamed(
                  SelectedTicketScreen.routeName,
                  arguments: SelectedTicketProvider(
                      _eventData.eventList[index],
                      _eventData.getTicketsForEventId(_eventData.eventList[index].id)
                  ),
                );
              },
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                elevation: 3,
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 60,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            dateFormatShortMonth.format(_eventData.eventList[index].startTime),
                            style: Theme.of(context).textTheme.title,
                          ),
                          Text(
                            _eventData.eventList[index].startTime.day.toString(),
                            style: Theme.of(context).textTheme.title,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _eventData.eventList[index].name,
                            style: Theme.of(context).textTheme.title,
                          ),
                          Text(
                            dateFormatTime.format(_eventData.eventList[index].startTime),
                            style: Theme.of(context).textTheme.body1,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                        image: DecorationImage(
                          fit: BoxFit.cover,
                          image: AssetImage('assets/ui_elements/rufus.jpg'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }
}

class DeviceConflict extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PopUpCard(
      content: Column(
        children: <Widget>[
          Text(
            activeOnAnotherDevice,
            style: Theme.of(context).textTheme.title,
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height: 25,
          ),
          Text(
            toAccessTickets,
            style: Theme.of(context).textTheme.body1,
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height: 25,
          ),
          PrimaryButton(
            text: relocateTickets,
            onPress: () {},
          ),
        ],
      ),
    );
  }
}

class EmailVerificationConflict extends StatelessWidget {

  final Function _mainButtonCallback;

  EmailVerificationConflict(this._mainButtonCallback);

  @override
  Widget build(BuildContext context) {
    return PopUpCard(
      content: Column(
        children: <Widget>[
          Text(
            emailConfirmationRequired,
            style: Theme.of(context).textTheme.title,
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height: 25,
          ),
          Text(
            pleaseConfirmEmail,
            style: Theme.of(context).textTheme.body1,
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height: 25,
          ),
          PrimaryButton(
            text: iveConfirmedEmail,
            isActive: true,
            onPress: () {
              _mainButtonCallback();
            },
          ),
        ],
      ),
    );
  }
}

class MissingTicket extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return PopUpCard(
      content: Column(
        children: <Widget>[
          Text(
            noEvents,
            style: Theme.of(context).textTheme.title,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 25),
          Text(
            noTickets,
            style: Theme.of(context).textTheme.body1,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 25),

          GestureDetector(
            child: Text(contactUs,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 18,
                )),
            onTap: () {
              contactSupport();
            },
          ),
        ],
      ),
    );
  }
}

class PopUpCard extends StatelessWidget {
  final Column content;

  PopUpCard({this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 30, 16, 0),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 30, 16, 30),
                    child: content,
                  ),
                ),
              ),
            ],
          ),
          Expanded(

            child: SizedBox(),
          ),
        ],
      ),
    );
  }
}
