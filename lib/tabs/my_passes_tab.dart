import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/providers/selected_ticket_provider.dart';
import 'package:foria/providers/ticket_provider.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria/utils/utils.dart';
import 'package:foria/widgets/contact_support.dart';
import 'package:foria/widgets/primary_button.dart';
import 'package:provider/provider.dart';

import '../screens/selected_ticket_screen.dart';

class MyPassesTab extends StatefulWidget {
  static List<String> date = ['day 1', 'day 2'];

  @override
  _MyPassesTabState createState() => _MyPassesTabState();
}

class _MyPassesTabState extends State<MyPassesTab> {

  bool _isFirstRun = true;
  bool _isLoading = true;
  bool _isUserLoggedIntoAnotherDevice = true;
  bool _isUserEmailVerified = false;

  @override
  void didChangeDependencies() async {

    if (_isFirstRun) {

      setState(() {
        _isLoading = true;
      });

      isUserEmailVerified().then((isEmailVerified) {

        setState(() {

          _isUserEmailVerified = isEmailVerified;

          if (_isUserEmailVerified) {

            //Email is verified. Set spinner to load tickets.
            _isLoading = true;
            Provider.of<TicketProvider>(context).fetchUserTickets().then((_) {
              _isLoading = false; //All done. Everything is fully loaded.
            });
          } else {
            _isLoading = false;
          }
        });
      });

      _isFirstRun = false;
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

    if (!_isUserEmailVerified) {
      return EmailVerificationConflict(this.emailVerifyCallback);
    }

    if (_isUserLoggedIntoAnotherDevice) {
      return DeviceConflict();
    }

    if (_eventData.eventList.length <= 0) {
      return MissingTicket();
    }

    return EventCard();
  }

  void emailVerifyCallback() async {

    await forceTokenRefresh();
    if (await isUserEmailVerified()) {
      setState(() {
        _isUserEmailVerified = true;
      });
    }
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
            isActive: true,
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
