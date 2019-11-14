import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/providers/event_provider.dart';
import 'package:foria/screens/ticket_scan_screen.dart';
import 'package:foria/utils/constants.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria/widgets/settings_item.dart';
import 'package:foria_flutter_client/api.dart';
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

  ///
  /// Fires network call to load and cache events.
  ///
  Future<void> _loadAttendees(String eventId) async {

    try {
      _attendeeList = await _eventProvider.getAttendeesForEvent(eventId);
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

  @override
  Widget build(BuildContext context) {

    final Map<String, dynamic> args = ModalRoute.of(context).settings.arguments as Map<String, dynamic>;
    if (widget._eventId == null) {
      if (args == null || args['eventId'] == null) {
        _eventId = widget._eventId;
      } else {
        _eventId = args['eventId'];
      }
    }


    Widget child;
    if (_currentState == _LoadingState.INITIAL_LOAD) {
      child = Center(child: CupertinoActivityIndicator(radius: 15));
      _loadAttendees();
    } else if (_currentState == _LoadingState.EVENTS_LOADED) {
      child = EventList();
    } else if (_currentState == _LoadingState.NO_EVENTS_AVAILABLE) {
      child = NoEvent();
    } else {
      child = ErrorTryAgainText(() => _loadAttendees());
    }
    
    //TODO: add refresh indicator
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
        body:
        Provider<List<Attendee>>.value(
          value: _attendeeList,
          child: SafeArea(
            child: Column(
              children: <Widget>[
                SizedBox(height: 20),
                Text(
                  ticketsSold + _attendeeList.length.toString(), //TODO:link this
                  style: Theme.of(context).textTheme.headline,
                ),
                SizedBox(height: 20),
                MajorSettingItemDivider(),
                Expanded(
                  child: ListView.separated(
                    itemCount: _attendeeList.length, //TODO:link this
                    separatorBuilder: (BuildContext context, int index) => Divider(height: 0,),
                    itemBuilder: (context, index) {
                      return AttendeeItem(index);
                    }),
                ),
              ],
            ),
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

  AttendeeItem(this.index); //TODO:remove once provider is hooked up

  @override
  _AttendeeItemState createState() => _AttendeeItemState();

}

class _AttendeeItemState extends State<AttendeeItem> {

  static const double _rowHeight = 70.0;
  bool _isLoading = false;
  Widget child;

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
    Attendee attendee = Provider.of<List<Attendee>>(context)[widget.index];
    String formattedName = attendee.lastName + ', ' + attendee.firstName;
    String status = attendee.ticket.status;

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
          _attendeeText(formattedName, attendee.ticket.ticketTypeConfig.name),
          Expanded(child: Container(),),
          OutlineButton(
            child: Text(checkInText),
            borderSide: BorderSide(
              color: constPrimaryColor,
            ),
            highlightedBorderColor: constPrimaryColor,
            textColor: constPrimaryColor,
            onPressed: () => status = ticketStatusRedeemed,
          ),
          SizedBox(width: 16),
        ],
      );
    }
    return child;

  }
}
