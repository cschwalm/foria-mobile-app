import 'package:flutter/material.dart';
import 'package:foria/providers/ticket_provider.dart';
import 'package:provider/provider.dart';

import '../screens/selected_ticket_screen.dart';

class MyPassesTab extends StatefulWidget {

  static List<String> date = ['day 1', 'day 2'];

  @override
  _MyPassesTabState createState() => _MyPassesTabState();
}

class _MyPassesTabState extends State<MyPassesTab> {

  bool _isInit = true;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {

    if (_isInit) {

      setState(() {
        _isLoading = true;
      });

      Provider.of<TicketProvider>(context).fetchUserTickets().then((_) {

        setState(() {
          _isLoading = false;
        });
      });

      _isInit = false;
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading ? CircularProgressIndicator() : new _EventList();
  }
}

class _EventList extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Consumer<TicketProvider>(builder: (context, ticketProvider, child) {
      return ListView.builder(
          itemCount: ticketProvider.eventList.length + 1,
          itemBuilder: (context, index) {
            if (index == ticketProvider.eventList.length) {
              return MissingTicket();
            } else {
              return EventCard(
                index: index,
              );
            }
          });
    });
  }
}

class EventCard extends StatelessWidget {
  const EventCard({
    Key key,
    @required this.index,
  }) : super(key: key);

  final int index;

  @override
  Widget build(BuildContext context) {
    return Consumer<TicketProvider>(builder: (context, ticketProvider, child) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed(
              SelectedTicketScreen.routeName,
              arguments: null,
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
                        "Apr",
                        style: Theme.of(context).textTheme.title,
                      ),
                      Text(
                        "20",
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
                        ticketProvider.eventList[index].name,
                        style: Theme.of(context).textTheme.title,
                      ),
                      Text(
                        '8:00PM - Late',
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

class MissingTicket extends StatelessWidget {
  const MissingTicket({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        height: 80,
        child: Column(
          children: <Widget>[
            Text(
              'Missing your tickets?',
              style: Theme.of(context).textTheme.title,
            ),
            Text('Contact Us',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 14,
                )),
          ],
        ),
      ),
    );
  }
}
