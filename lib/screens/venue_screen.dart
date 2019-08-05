import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/widgets/primary_button.dart';

import '../utils/strings.dart';

class VenueScreen extends StatelessWidget {

  static const routeName = '/selected-ticket';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(venueAccount),
        backgroundColor: Theme.of(context).primaryColorDark,
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(
          children: <Widget>[
            (),
            SizedBox(
              height: 40,
            ),
            Expanded(
              child: PassBody(),
            ),
            PrimaryButton(
              text: scanTickets,
              icon: Icons.camera,
              onPress: () {},
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.fromLTRB(16,0,16,20),
                    child: PrimaryButton(
                      text: textLogout,
                      onPress: () {},
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}