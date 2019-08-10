import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/main.dart';
import 'package:foria/providers/selected_ticket_provider.dart';
import 'package:foria/utils/static_images.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria/widgets/primary_button.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'register_and_transfer_screen.dart';

class SelectedTicketScreen extends StatefulWidget {

  static const routeName = '/selected-ticket';
  final SelectedTicketProvider selectedTicketProvider;

  SelectedTicketScreen({this.selectedTicketProvider});

  @override
  _SelectedTicketScreenState createState() => _SelectedTicketScreenState();
}

class _SelectedTicketScreenState extends State<SelectedTicketScreen> {

  SelectedTicketProvider _selectedTicketProvider;

  @override
  Widget build(BuildContext context) {

    _selectedTicketProvider = widget.selectedTicketProvider != null ?
    widget.selectedTicketProvider : ModalRoute.of(context).settings.arguments as SelectedTicketProvider;

    return Scaffold(
      appBar: AppBar(
        title: Text(foriaPass),
        backgroundColor: Theme.of(context).primaryColorDark,
      ),
      backgroundColor: settingsBackgroundColor,
      body: ChangeNotifierProvider(
        builder: (context) => (_selectedTicketProvider),
        child: PassBody(),
      )
    );
  }
}

class PassBody extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    final SelectedTicketProvider selectedTicketProvider = Provider.of<SelectedTicketProvider>(context, listen: false);
    final int passCount = selectedTicketProvider.eventTickets.length;

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

    final SelectedTicketProvider selectedTicketProvider = Provider.of<SelectedTicketProvider>(context, listen: false);
    final passNumber = index + 1;

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
                selectedTicketProvider.eventTickets[index].ticketTypeConfig.name,
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

    final SelectedTicketProvider selectedTicketProvider = Provider.of<SelectedTicketProvider>(context, listen: false);

    DateTime startDateTime = selectedTicketProvider.event.startTime;
    String month = dateFormatShortMonth.format(startDateTime);
    String day = startDateTime.day.toString();
    String startClockTime = dateFormatTime.format(startDateTime);

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
                    '$month\n$day',
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
                  selectedTicketProvider.event.name,
                  style: Theme.of(context).textTheme.headline,
                ),
                Text(
                  selectedTicketProvider.event.address.venueName,
                  style: Theme.of(context).textTheme.body1,
                ),
                Text(
                  startClockTime,
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

    final SelectedTicketProvider selectedTicketProvider = Provider.of<SelectedTicketProvider>(context, listen: false);
    final addr = selectedTicketProvider.event.address;

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

        var url = googleMapsSearchUrl + Uri.encodeFull(addr.streetAddress + " " + addr.city + " " + addr.state + " " + addr.zip);

        if (await canLaunch(url)) {
          await launch(url);
        } else {
          print('Could not launch $url');
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
