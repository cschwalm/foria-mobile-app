import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/providers/attendee_provider.dart';
import 'package:foria/providers/event_provider.dart';
import 'package:foria/providers/ticket_provider.dart';
import 'package:foria/screens/ticket_scan_screen.dart';
import 'package:foria/utils/constants.dart';
import 'package:foria/utils/message_stream.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria/widgets/errors/error_try_again_column.dart';
import 'package:foria/widgets/errors/simple_error.dart';
import 'package:foria/widgets/settings_item.dart';
import 'package:foria/widgets/show_pop_up_confirm.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

///
/// Screen displays a list of all tickets to a particular event and a button to the scan screen.
/// Includes the total number of tickets sold and ability to manually check-in attendees.
/// Each ticket displays the attendee name and ticket type
///
class AttendeeListScreen extends StatefulWidget {

  static const routeName = '/attendee-list-screen';
  final String _eventId;

  AttendeeListScreen([this._eventId]);

  @override
  _AttendeeListScreenState createState() => _AttendeeListScreenState();
}
enum _LoadingState {

  INITIAL_LOAD,
  NETWORK_ERROR,
  EVENTS_LOADED,
  NO_EVENTS_AVAILABLE
}

class _AttendeeListScreenState extends State<AttendeeListScreen> {

  String _eventId;
  List<Attendee> _attendeeList;
  _LoadingState _currentState;
  EventProvider _eventProvider;
  AttendeeProvider _attendeeProvider;

  @override
  void initState() {
    _eventProvider = GetIt.instance<EventProvider>();
    _attendeeProvider = GetIt.instance<AttendeeProvider>();
    _currentState = _LoadingState.INITIAL_LOAD;
    super.initState();
  }

  ///
  /// Fires network call to load List<Attendee>.
  ///
  Future<void> _loadAttendees(String eventId) async {

    try {
      _attendeeList = await _eventProvider.getAttendeesForEvent(eventId);
      _attendeeProvider.setAttendeeList(_attendeeList);
      setState(() {
        if (_attendeeList == null || _attendeeList.isEmpty) {
          _currentState = _LoadingState.NO_EVENTS_AVAILABLE;
        } else {
          _currentState = _LoadingState.EVENTS_LOADED;
        }
      });
    } catch (e) {
      setState(() {
        _currentState = _LoadingState.NETWORK_ERROR;
      });
    }
  }

  ///
  /// Shown if there are no attendees in list
  ///
  Widget _noAttendees() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: <Widget>[
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(noAttendeesAvailable,
                  style: Theme.of(context).textTheme.title,
                  textAlign: TextAlign.center,),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _basicScaffold(Widget child) {
    return Scaffold(
        appBar: AppBar(
          title: Text(checkInText),
          backgroundColor: Theme.of(context).primaryColorDark,
        ),
        body: child
    );
  }

  @override
  Widget build(BuildContext context) {

    Widget child;

    // Receives eventId from navigation route. eventId can also be set as an AttendeeListScreen parameter for testing
    final Map<String, dynamic> args = ModalRoute.of(context).settings.arguments as Map<String, dynamic>;
    if (widget._eventId == null) {
      if (args == null || args['eventId'] == null) {
        _eventId = widget._eventId;
      } else {
        _eventId = args['eventId'];
      }
    }

    if (_currentState == _LoadingState.INITIAL_LOAD) {
      child = _basicScaffold(Center(child: CupertinoActivityIndicator(radius: 15)));
      _loadAttendees(_eventId);
    } else if (_currentState == _LoadingState.EVENTS_LOADED) {
      child = AttendeeListScaffold();
    } else if (_currentState == _LoadingState.NO_EVENTS_AVAILABLE) {
      child = _basicScaffold(_noAttendees());
    } else {
      child = _basicScaffold(ErrorTryAgainColumn(() => _loadAttendees(_eventId)));
    }

    return RefreshIndicator(
        onRefresh: () => _loadAttendees(_eventId),
        displacement: 110,
        child: ChangeNotifierProvider<AttendeeProvider>.value(
            value: _attendeeProvider,
            child: child
        ));
  }
}

///
/// Scaffold to display ticket sales and scan button. Attendee list items are children
///
class AttendeeListScaffold extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final attendeeData = Provider.of<AttendeeProvider>(context, listen: true);
    final List<Attendee> attendeeList = attendeeData.attendeeList;

    return Scaffold(
        appBar: AppBar(
          title: Text(checkInText),
          backgroundColor: Theme.of(context).primaryColorDark,
        ),
        floatingActionButton: SizedBox(
          height: 80,
          width: 80,
          child: FloatingActionButton(
            backgroundColor: constPrimaryColor.withOpacity(0.5),
            child: Image.asset(
              scanButton,
              height: 70,
              width: 70,
            ),
            onPressed: () => Navigator.pushNamed(context, TicketScanScreen.routeName),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              SizedBox(height: 20),
              Text(
                ticketsSold + attendeeList.length.toString(),
                style: Theme.of(context).textTheme.headline,
              ),
              SizedBox(height: 20),
              MajorSettingItemDivider(),
              Expanded(
                child: ListView.separated(
                    itemCount: attendeeList.length,
                    separatorBuilder: (BuildContext context, int index) => Divider(height: 0),
                    itemBuilder: (context, index) {
                      if (attendeeList.length == index + 1) {
                        return Column(
                          children: <Widget>[
                            AttendeeItem(index),
                            Divider(height: 0),
                            SizedBox(height: 70)
                          ],
                        );
                      }
                      return AttendeeItem(index);
                    }),
              ),
            ],
          ),
        )
    );
  }
}

///
/// Creates the row for each ticket in the ticket list. Includes manual check-in button.
/// The information is displayed differently if a ticket has been Redeemed or not Redeemed
///
class AttendeeItem extends StatefulWidget {

  final int index;

  AttendeeItem(this.index);

  @override
  _AttendeeItemState createState() => _AttendeeItemState();
}

class _AttendeeItemState extends State<AttendeeItem> {

  static const double _rowHeight = 70.0;
  bool _isLoading = false;
  TicketProvider _ticketProvider;
  Widget child;
  String status;

  @override
  void initState() {
    _ticketProvider = GetIt.instance<TicketProvider>();
    super.initState();
  }

  Column _attendeeText (String name, String ticketType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          name,
          style: Theme.of(context).textTheme.title,
        ),
        Text(
          ticketType,
          style: Theme.of(context).textTheme.body2,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final attendeeData = Provider.of<AttendeeProvider>(context, listen: true);
    Attendee attendee = attendeeData.attendeeList[widget.index];
    String formattedName = attendee.lastName.trim() + ', ' + attendee.firstName.trim();
    status = attendee.ticket.status;
    final MessageStream messageStream = GetIt.instance<MessageStream>();

    messageStream.addListener((errorMessage) {
      showErrorAlert(context, offlineError);
    });

    if (_isLoading) {
      child = Container(
        child: Center(child: CupertinoActivityIndicator()),
        color: settingsBackgroundColor,
        height: _rowHeight,
        width: double.infinity,
      );
    } else if (status == ticketStatusRedeemed){
      child = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        key: Key('redeemed attendee'),
        children: <Widget>[
          Container(
            color: Colors.green,
            height: _rowHeight,
            width: 10,
          ),
          SizedBox(width: 6),
          _attendeeText(formattedName, attendee.ticket.ticketTypeConfig.name),
        ],
      );
    } else {
      child = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            height: _rowHeight,
            width: 16,
          ),
          Expanded(child: _attendeeText(formattedName, attendee.ticket.ticketTypeConfig.name)),
          OutlineButton(
              child: Text(checkInText),
              borderSide: BorderSide(
                color: constPrimaryColor,
              ),
              highlightedBorderColor: constPrimaryColor,
              textColor: constPrimaryColor,
              onPressed: () {
                showPopUpConfirm(context, confirmCheckIn, thisNonReversible, () => _manualRedeemTicket(attendee));
              }
          ),
          SizedBox(width: 16),
        ],
      );
    }
    return child;
  }

  ///
  /// Fires network call to manually redeem ticket.
  ///
  Future<void> _manualRedeemTicket(Attendee attendee) async {

    final attendeeData = Provider.of<AttendeeProvider>(context, listen: true);

    setState(() {
      _isLoading = true;
    });

    _ticketProvider.manualRedeemTicket(attendee.ticket.id).then((ticket) {

      if (ticket.status == ticketStatusRedeemed) {
        attendeeData.markAttendeeRedeemed(attendee);
      } else {
        log('Manual Ticket Redeem failed for ticket id: ${attendee.ticket.id}', level: Level.SEVERE.value);
      }

    }).catchError((e) {

      log('Manual Ticket Redeem failed for ticket id: ${attendee.ticket.id}', level: Level.SEVERE.value);

    }).whenComplete((){

      setState(() {
        _isLoading = false;
      });
    });
  }
}
