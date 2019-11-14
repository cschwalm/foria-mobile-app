import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/providers/selected_ticket_provider.dart';
import 'package:foria/screens/ticket_scan_screen.dart';
import 'package:foria/utils/constants.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria/widgets/settings_item.dart';
import 'package:provider/provider.dart';

///
/// Screen displays a list of all tickets to a particular event and a button to the scan screen.
/// Includes the total number of tickets sold and ability to manually check-in attendees.
/// Each ticket displays the attendee name and ticket type
///
class AttendeeListScreen extends StatefulWidget {

  static const routeName = '/attendee-list-screen';
//  final SelectedTicketProvider _selectedTicketProvider;
//
//  AttendeeListScreen([this._selectedTicketProvider]);

  @override
  _AttendeeListScreenState createState() => _AttendeeListScreenState();
}

class _AttendeeListScreenState extends State<AttendeeListScreen> {

//  SelectedTicketProvider _selectedTicketProvider;

  @override
  Widget build(BuildContext context) {

//    final Map<String, dynamic> args = ModalRoute.of(context).settings.arguments as Map<String, dynamic>;
//    if (_selectedTicketProvider == null) {
//      if (args == null || args['event'] == null) {
//        _selectedTicketProvider = widget._selectedTicketProvider;
//      } else {
//        _selectedTicketProvider = new SelectedTicketProvider(args['event']);
//      }
//    }
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
//        ChangeNotifierProvider<SelectedTicketProvider>.value(
//          value: _selectedTicketProvider,
//          child:
          SafeArea(
            child: Column(
              children: <Widget>[
                SizedBox(height: 20),
                Text(
                  ticketsSold + '123', //TODO:link this
                  style: Theme.of(context).textTheme.headline,
                ),
                SizedBox(height: 20),
                MajorSettingItemDivider(),
                Expanded(
                  child: ListView.separated(
                    itemCount: 20, //TODO:link this
                    separatorBuilder: (BuildContext context, int index) => Divider(height: 0,),
                    itemBuilder: (context, index) {
                      String ticketId = '12345'; //TODO:pull ticketId from provider
                      return AttendeeItem(ticketId,index);
                    }),
                ),
              ],
            ),
          ),
//        )
    );
  }
}

///
/// Creates the row for each ticket in the ticket list. Includes manual check-in button.
/// The information is displayed differently if a ticket has been Redeemed or not Redeemed
///
class AttendeeItem extends StatefulWidget {

  final String ticketId;
  final int index;

  AttendeeItem(this.ticketId, this.index); //TODO:remove once provider is hooked up

  @override
  _AttendeeItemState createState() => _AttendeeItemState();

}

class _AttendeeItemState extends State<AttendeeItem> {

  static const double _rowHeight = 70.0;
  bool isLoading = false;
  String status;
  Widget child;

  @override
  Widget build(BuildContext context) {

    Widget attendeeText = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Stetson, Billy', //TODO:link this
          style: Theme.of(context).textTheme.title,
        ),
        Text(
          'General Admission', //TODO:link this
          style: Theme.of(context).textTheme.body2,
        ),
      ],
    );

    if (widget.index.isEven) { //TODO:remove once provider is hooked up
      status = 'REDEEMED';
    } else {
      isLoading = false;
      status = '1';
    }

    if (isLoading) {
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
          attendeeText,
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
          attendeeText,
          Expanded(child: Container(),),
          OutlineButton(
            child: Text('Check-in',),
            borderSide: BorderSide(
              color: constPrimaryColor,
            ),
            highlightedBorderColor: constPrimaryColor,
            textColor: constPrimaryColor,
            onPressed: (){},
          ),
          SizedBox(width: 16),
        ],
      );
    }
    return child;

  }
}
