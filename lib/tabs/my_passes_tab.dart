import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/providers/selected_ticket_provider.dart';
import 'package:foria/providers/ticket_provider.dart';
import 'package:foria/widgets/contact_support.dart';
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
  bool _isUserLoggedIntoAnotherDevice = false;

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
    final _eventData = Provider.of<TicketProvider>(context, listen: false);

    if (_isLoading) {
      return CupertinoActivityIndicator(
        radius: 15,
      );
    }
    if (_isUserLoggedIntoAnotherDevice) {
      return Text('email is not confirmed');
    }
    if (_eventData.eventList.length >= 1) {
      return EventCard();
    }
    return MissingTicket();
  }
}

class EventCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final _eventData = Provider.of<TicketProvider>(context, listen: false);

      return ListView.builder(
          itemCount: _eventData.eventList.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed(
                    SelectedTicketScreen.routeName,
                    arguments: SelectedTicketProvider(
                        _eventData.eventList[index], null), //TODO: Use new method
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
                              _eventData.eventList[index].name,
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
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
      child: Container(
        height: 80,
        child: Column(
          children: <Widget>[
            Text(
              'You don\'t have any upcoming events',
              style: Theme.of(context).textTheme.title,
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 10
            ),
            Text(
              'If you can\'t find your tickets, \nplease first check your \nemail order confirmation.',
              style: Theme.of(context).textTheme.body1,
              textAlign: TextAlign.center,
            ),
            SizedBox(
                height: 10
            ),
            GestureDetector(
              child: Text('Otherwise, Contact Us',
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
      ),
    );
  }
}
