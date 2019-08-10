import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/main.dart';
import 'package:foria/providers/selected_ticket_provider.dart';
import 'package:foria/utils/static_images.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria/widgets/primary_button.dart';
import 'package:url_launcher/url_launcher.dart';

import 'register_and_transfer_screen.dart';

class SelectedTicketScreen extends StatelessWidget {
  static const routeName = '/selected-ticket';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(foriaPass),
        backgroundColor: Theme.of(context).primaryColorDark,
      ),
      backgroundColor: settingsBackgroundColor,
      body: PassBody(),
    );
  }
}

class PassBody extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final _selectedEventData =
    ModalRoute.of(context).settings.arguments as SelectedTicketProvider;

    final int passCount = _selectedEventData.eventTickets.length;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: PageView.builder(
        // store this controller in a State to save the carousel scroll position
        controller: PageController(viewportFraction: .9),
        itemCount: passCount,
        itemBuilder: (BuildContext context, int itemIndex) {
          return PassCard(itemIndex, passCount);
        },
      ),
    );
  }
}

class PassCard extends StatelessWidget {
  final int index;
  final int passCount;

  PassCard(this.index, this.passCount);

  @override
  Widget build(BuildContext context) {
    final _selectedEventData =
    ModalRoute.of(context).settings.arguments as SelectedTicketProvider;
    final passNumber = index+1;


    return SafeArea(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              EventInfo(),
              SizedBox(height: 5,),
              Directions(),
              SizedBox(height: 30,),
              Text(
                'Pass $passNumber of $passCount',
                style: Theme.of(context).textTheme.title,
              ),
              SizedBox(height: 5,),
              Text(
                _selectedEventData.eventTickets[index].ticketTypeConfig.name,
                style: Theme.of(context).textTheme.title,
              ),
              SizedBox(
                height: 20,
              ),
              Image.asset('assets/ui_elements/qr1.png'),
              SizedBox(
                height: 10,
              ),
              PassRefresh(),
              Expanded(child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  PassOptions(),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class EventInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final _selectedEventData =
        ModalRoute.of(context).settings.arguments as SelectedTicketProvider;

    DateTime _startDateTime = _selectedEventData.event.startTime;
    String _month = dateFormatShortMonth.format(_startDateTime);
    String _day = _startDateTime.day.toString();
    String _startClockTime = dateFormatTime.format(_startDateTime);

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
                      '$_month\n$_day',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.display1,
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
                    _selectedEventData.event.name,
                    style: Theme.of(context).textTheme.headline,
                  ),
                  Text(
                    _selectedEventData.event.address.venueName,
                    style: Theme.of(context).textTheme.body1,
                  ),
                  Text(
                    _startClockTime,
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

class Directions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final _eventData =
        ModalRoute.of(context).settings.arguments as SelectedTicketProvider;
    final _add = _eventData.event.address;

    return GestureDetector(
        child: Row(
          children: <Widget>[
            Icon(
              Icons.location_on,
              color: Theme.of(context).primaryColor,
            ),
            Text(
              '' + directionsText,
              style: TextStyle(
                  fontSize: 18, color: Theme.of(context).primaryColor),
            ),
          ],
        ),
        onTap: () async {
          var url = googleMapsSearchUrl +
              Uri.encodeFull(_add.streetAddress) +
              '%20' +
              Uri.encodeFull(_add.city) +
              '%20' +
              Uri.encodeFull(_add.state);
          if (await canLaunch(url)) {
            await launch(url);
          } else {
            throw 'Could not launch $url';
          }
        },
    );
  }
}



class PassRefresh extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          passRefresh,
          style: Theme.of(context).textTheme.body2,
        ),
        Stack(
          children: <Widget>[
            Image.asset(
              refreshIcon,
              width: 30,
              height: 30,
            ),
            Container(
              height: 30,
              width: 30,
              alignment: Alignment.center,
              child: Text(
                "55",
                style: Theme.of(context).textTheme.body2,
              ),
            ),
          ],
        )
      ],
    );
  }
}

class PassOptions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
          children: <Widget>[
            PrimaryButton(
              text: textTransfer,
              onPress: () {
                Navigator.of(context).pushNamed(
                  RegisterAndTransferScreen.routeName,
                  arguments: null,
                );
              },
            ),
          ],
    );
  }
}
