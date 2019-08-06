import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/providers/selected_ticket_provider.dart';
import 'package:foria/utils/static_images.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria/widgets/primary_button.dart';

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
      body: Padding(
        padding: EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(
          children: <Widget>[
            EventInfo(),
            SizedBox(
              height: 40,
            ),
            Expanded(
              child: PassBody(),
            ),
            PassOptions(),
          ],
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

    return Row(
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
                  'Apr\n20',
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
                "Brooklyn Mirage",
                style: Theme.of(context).textTheme.body1,
              ),
              Text(
                "7:00pm - Late",
                style: Theme.of(context).textTheme.body1,
              ),
            ],
            crossAxisAlignment: CrossAxisAlignment.start,
          ),
        ),
      ],
    );
  }
}

class PassBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          "General Admission",
          style: Theme.of(context).textTheme.title,
        ),
        Text(
          "1/3 passes",
          style: Theme.of(context).textTheme.body2,
        ),
        SizedBox(
          height: 20,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(CupertinoIcons.left_chevron),
            SizedBox(
              width: 20,
            ),
            Image.asset('assets/ui_elements/qr1.png'),
            SizedBox(
              width: 20,
            ),
            Icon(CupertinoIcons.right_chevron),
          ],
        ),
        SizedBox(
          height: 10,
        ),
        Row(
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
        ),
      ],
    );
  }
}

class PassOptions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          passOptions,
          style: Theme.of(context).textTheme.title,
        ),
        SizedBox(
          height: 10,
        ),
        Container(
          height: 45,
          child: Row(
            children: <Widget>[
              Expanded(
                child: PrimaryButton(
                  text: textTransfer,
                  onPress: () {
                    Navigator.of(context).pushNamed(
                      RegisterAndTransferScreen.routeName,
                      arguments: null,
                    );
                  },
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}