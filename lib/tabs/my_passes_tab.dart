import 'package:flutter/material.dart';
import 'package:foria/providers/ticket_provider.dart';
import 'package:provider/provider.dart';

import '../screens/selected_ticket_screen.dart';

class MyPassesTab extends StatelessWidget {
  static List<String> date = ['day 1', 'day 2'];
  static List<String> photos = [
    'assets/ui_elements/griz.jpg',
    'assets/ui_elements/rufus.jpg',
    'assets/ui_elements/rufus.jpg',
    'assets/ui_elements/rufus.jpg',
    'assets/ui_elements/rufus.jpg',
    'assets/ui_elements/rufus.jpg',
    'assets/ui_elements/rufus.jpg',
    'assets/ui_elements/rufus.jpg'
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<TicketProvider>(builder: (context, ticketProvider, child) {
      return ListView.builder(
          itemCount: ticketProvider.userTicketList.length,
          itemBuilder: (context, index) {
            if (index == ticketProvider.userTicketList.length) {
              return MissingTicket();
            } else {
              return EventCard(
                photos: photos,
                index: index,
                ticketProvider: ticketProvider,
              );
            }
          });
    });
  }
}

class EventCard extends StatelessWidget {
  const EventCard({
    Key key,
    @required this.photos,
    @required this.index,
    this.ticketProvider,
  }) : super(key: key);

  final List<String> photos;
  final int index;
  final ticketProvider;

  @override
  Widget build(BuildContext context) {
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
                      ticketProvider.userTicketList.elementAt(index).eventId,
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
                    image: AssetImage(photos[1]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
