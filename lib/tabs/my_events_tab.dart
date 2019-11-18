import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/providers/ticket_provider.dart';
import 'package:foria/utils/auth_utils.dart';
import 'package:foria/utils/constants.dart';
import 'package:foria/utils/firebase_events.dart';
import 'package:foria/utils/message_stream.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria/widgets/errors/image_unavailable.dart';
import 'package:foria/widgets/errors/simple_error.dart';
import 'package:foria/widgets/primary_button.dart';
import 'package:get_it/get_it.dart';
import 'package:ntp/ntp.dart';
import 'package:provider/provider.dart';

import '../screens/my_tickets_screen.dart';

class MyEventsTab extends StatefulWidget {

  @override
  _MyEventsTabState createState() => _MyEventsTabState();
}

enum _LoadingState {

  EMAIL_VERIFY,
  LOAD_TICKETS,
  DEVICE_CHECK,
  DONE
}

///
/// Contains simple state machine to handle three flows.
/// Step 1: Tab opened. Nothing has been done. We need to display loading and check email verify.
/// Step 2: Email is verified, display spinner and load tickets.
/// Step 3: Check if tickets are active on this device. If not stop and show error.
/// Step 4: Display tickets results.
///
class _MyEventsTabState extends State<MyEventsTab> with AutomaticKeepAliveClientMixin<MyEventsTab> {

  AuthUtils _authUtils;
  TicketProvider _ticketProvider;

  _LoadingState _currentState;
  bool _isUserEmailCheckFinished;
  bool _isTicketsLoaded;
  bool _isTicketsReactivateLoading;

  @override
  void initState() {

    _authUtils = GetIt.instance<AuthUtils>();
    _ticketProvider = GetIt.instance<TicketProvider>();
    _currentState = _LoadingState.EMAIL_VERIFY;

    _isUserEmailCheckFinished = false;
    _isTicketsLoaded = false;
    _isTicketsReactivateLoading = false;

    super.initState();
  }

  ///
  /// Build method preforms two key actions.
  /// 1) Determines the new state to be resolved to.
  /// 2) Builds the correct widget based on new state.
  ///
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

    super.build(context);
    switch (_currentState) {

      case _LoadingState.EMAIL_VERIFY:

        if (!_isUserEmailCheckFinished) {
          _preformUserEmailCheck();
        }

        break;

      case _LoadingState.LOAD_TICKETS:
      case _LoadingState.DEVICE_CHECK:

        if (!_isTicketsLoaded) {
          _loadTicketsAndSetState();
        }
        break;

      case _LoadingState.DONE:
        //All checks passed. Show tickets to user.
        //Moving permission here is better UI because popup shows with content on screen.
        final FirebaseMessaging firebaseMessaging = FirebaseMessaging();
        firebaseMessaging.requestNotificationPermissions();
        firebaseMessaging.getToken().then((token) => _ticketProvider.registerDeviceToken(token));

        //Display pop-up if user has incorrect clock time.
        _preformUserTimeCheck(context);

        break;
    }

    return ChangeNotifierProvider.value(
        value: _ticketProvider,
        child: determineFinalWidget()
    );
  }

  ///
  /// Triggers ticket load and resets spinner.
  ///
  Future<void> _loadTicketsAndSetState() async {

    _isTicketsLoaded = false;
    _currentState = _LoadingState.LOAD_TICKETS;

    //Email is verified. Load tickets and stop spinner when completed.
    TicketProvider ticketProvider = _ticketProvider;
    Future<void> result = ticketProvider.loadUserDataFromNetwork();
    result.then((_) {
      setState(() {
        _isTicketsLoaded = true;

        //Check if tickets are active on this device only if online.
        if (!ticketProvider.ticketsActiveOnOtherDevice) {
          _currentState = _LoadingState.DONE;
        } else {
          _currentState = _LoadingState.DEVICE_CHECK;
        }

      });
    }).catchError((error) {

      print('getTickets network call failed. Loading from offline database.');
      showErrorAlert(context, ticketLoadingFailure);
      ticketProvider.loadUserDataFromLocalDatabase().then((_) {
        setState(() {
          _isTicketsLoaded = true;
          _currentState = _LoadingState.DONE;
        });
      }).catchError((error) {
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

    TicketProvider ticketProvider = _ticketProvider;
    try {
      await ticketProvider.loadUserDataFromNetwork();

      setState(() {
        if (ticketProvider.ticketsActiveOnOtherDevice) {
            debugPrint('Determined tickets are active on other device during refresh.');
            _currentState = _LoadingState.DEVICE_CHECK;
        } else {
          _currentState = _LoadingState.DONE;
        }
      });

    } catch (ex) {
      print('getTickets network call failed during manual refresh. Loading from offline database.');

      if (context != null) {
        showErrorAlert(context, ticketLoadingFailure);
      }

      await ticketProvider.loadUserDataFromLocalDatabase();
      setState(() {
        _currentState = _LoadingState.DONE;
      });
    }
  }

  ///
  /// Preforms check to see if the user is email verified by refreshing ID token.
  ///
  void _preformUserEmailCheck() {

    Future<bool> isUserEmailVerified = _authUtils.isUserEmailVerified();
    isUserEmailVerified.then((isEmailVerified) {
      setState(() {
        _isUserEmailCheckFinished = true;

        //If email is verified, set next state and start the initial load.
        if (isEmailVerified) {
          _currentState = _LoadingState.LOAD_TICKETS;
        }
      });
    });
  }

  Future<void> emailVerifyCallback() async {

    await _authUtils.forceTokenRefresh();
    bool isEmailVerified = await _authUtils.isUserEmailVerified();

    if (isEmailVerified) {
      _loadTicketsAndSetState();
    } else {
      showErrorAlert(context, 'Your email is not verified. Please click the \"Confirm Email\" button from our email titled \"Action Required: Verify Your Foria Email\". Thanks!');
    }
  }

  ///
  /// Disables button while reactivation is preformed.
  ///
  void _deviceCheckCallback() async {

    setState(() {
      _isTicketsReactivateLoading = true;
    });

    _ticketProvider.reactivateTickets().then((_) {
      setState(() {
        _isTicketsReactivateLoading = false;
        _currentState = _LoadingState.DONE;
      });
    });
  }

  ///
  /// Determines the correct widget to show after state processing has been preformed.
  ///
  Widget determineFinalWidget() {

    if ( (_currentState == _LoadingState.EMAIL_VERIFY && !_isUserEmailCheckFinished) ||
        (_currentState == _LoadingState.LOAD_TICKETS && !_isTicketsLoaded) ) {
      return CupertinoActivityIndicator(
        radius: 15,
      );
    }

    Widget finalStateWidget;
    if (_currentState == _LoadingState.EMAIL_VERIFY) {
      finalStateWidget = EmailVerificationConflict(emailVerifyCallback);
    } else if (_currentState == _LoadingState.DEVICE_CHECK) {
      finalStateWidget = DeviceConflict(_isTicketsReactivateLoading, _deviceCheckCallback);
    } else if (_ticketProvider.eventList.length <= 0) {
      finalStateWidget = MissingTicket(_awaitTicketLoad);
    } else {
      finalStateWidget = EventCard(_awaitTicketLoad);
    }

    return finalStateWidget;
  }

  ///
  /// Calculate the offset from the device and the NTP pool.
  /// If greater than 30 seconds (OTP TIME STEP), display a warning to user.
  ///
  void _preformUserTimeCheck(BuildContext context) async {

    //Check user's device time
    NTP.getNtpOffset().then((offset) {

      debugPrint('Calculated NTP time offset: $offset milliseconds.');

      if (offset.abs() >= 30000) {
        showErrorAlert(context, badPhoneTime);
        FirebaseAnalytics().logEvent(name: BAD_USER_TIME, parameters: {'offset': offset.abs()});
      }
    });
  }

  @override
  bool get wantKeepAlive => true;
}

///
/// Displays a list of event cards. Pressing allows user to navigate to selected event screen.
///
class EventCard extends StatelessWidget {

  final Function _refreshFunction;
  EventCard(this._refreshFunction);

  static const String eventCardKey = 'event_card_key';

  @override
  Widget build(BuildContext context) {
    final eventData = Provider.of<TicketProvider>(context, listen: true);
    final Duration timezoneOffset = DateTime.now().timeZoneOffset;
    final Duration timeDiff = new Duration(hours: timezoneOffset.inHours, minutes: timezoneOffset.inMinutes % 60);

    return RefreshIndicator(
        onRefresh: _refreshFunction,
        child: ListView.builder(
            itemCount: eventData.eventList.length,
            itemBuilder: (context, index) {
              DateTime serverStartTime = eventData.eventList[index].startTime;
              DateTime localStartTime = serverStartTime.add(timeDiff);

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: GestureDetector(
                  key: Key(eventCardKey+index.toString()),
                  onTap: () async {
                    FirebaseAnalytics().logEvent(name: TICKETS_VIEWED, parameters: {'eventId': eventData.eventList[index].id});
                    final result = await Navigator.of(context).pushNamed(
                      MyTicketsScreen.routeName,
                      arguments: {
                        'event': eventData.eventList[index],
                        'tickets': eventData.getTicketsForEventId(eventData.eventList[index].id)
                      },
                    );
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
                    if (result != null){
                      messageStream.announceMessage(ForiaNotification.message(MessageType.MESSAGE, result, null));
                    }
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
                                dateFormatShortMonth.format(localStartTime),
                                style: Theme.of(context).textTheme.title,
                              ),
                              Text(
                                localStartTime.day.toString(),
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
                                eventData.eventList[index].name,
                                style: Theme.of(context).textTheme.title,
                              ),
                              Text(
                                dateFormatTime.format(localStartTime),
                                style: Theme.of(context).textTheme.body1,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 100,
                          width: 100,
                          child: eventData.eventList[index].imageUrl == null ? null :
                          CachedNetworkImage(
                            placeholder: (context, url) =>
                                CupertinoActivityIndicator(),
                            errorWidget: (context, url, error) {
                              return ImageUnavailable();
                            },
                            imageUrl: eventData.eventList[index].imageUrl,
                            imageBuilder: (context, imageProvider) =>
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(10),
                                      bottomRight: Radius.circular(10),
                                    ),
                                    image: DecorationImage(
                                      image: imageProvider,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            })
    );
  }
}

///
/// Shown to user when tickets are active on a different device.
/// Button allows for ticket secret refresh.
///
class DeviceConflict extends StatelessWidget {

  final bool _isTicketReactivatePending;
  final Function _deviceConflictCallback;

  DeviceConflict(this._isTicketReactivatePending, this._deviceConflictCallback);

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
            onPress: _isTicketReactivatePending ? null : _deviceConflictCallback,
            isLoading: _isTicketReactivatePending,
          ),
        ],
      ),
    );
  }
}

class EmailVerificationConflict extends StatefulWidget {

  final Function _mainButtonCallback;

  EmailVerificationConflict(this._mainButtonCallback);

  @override
  _EmailVerificationConflictState createState() => _EmailVerificationConflictState();
}

class _EmailVerificationConflictState extends State<EmailVerificationConflict> {

  bool _isCheckingVerification = false;

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
            isLoading: _isCheckingVerification,
            onPress: _isCheckingVerification ? null :
                () async {
              setState(() {
                _isCheckingVerification = true;
              });

              await widget._mainButtonCallback();

              if (mounted) {
                setState(() {
                  _isCheckingVerification = false;
                });
              }

            },
          ),
        ],
      ),
    );
  }
}

///
/// Widget shows that the user has no tickets and allows swipe to refresh to load again.
///
class MissingTicket extends StatelessWidget {

  final Function _onRefreshFunctionCallback;

  MissingTicket(this._onRefreshFunctionCallback);

  @override
  Widget build(BuildContext context) {

    return RefreshIndicator(
      onRefresh: _onRefreshFunctionCallback,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Container(
          child: Center(
            child: PopUpCard(
              content: Column(
                children: <Widget>[
                  Text(
                    noTickets,
                    style: Theme.of(context).textTheme.title,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 25),
                  Text(
                    noEvents,
                    style: Theme.of(context).textTheme.body1,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 25),
                ],
              ),
            ),
          ),
          height: MediaQuery.of(context).size.height,
        ),
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
