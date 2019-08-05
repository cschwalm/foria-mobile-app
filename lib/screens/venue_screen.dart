import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/utils/utils.dart';
import 'package:foria/widgets/primary_button.dart';
import 'package:foria/widgets/settings_item.dart';

import '../utils/strings.dart';

class VenueScreen extends StatelessWidget {
  static const routeName = '/venue-screen';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(venueAccount),
        backgroundColor: Theme.of(context).primaryColorDark,
      ),
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 20,
          ),
          Container(
            color: Color(0xffbcbbc1),
            height: 0.3,
          ),
          SettingsItem(
            label: FAQ,
            content: SettingsNavigationIndicator(),
            onPress: () {},
          ),
          Container(
            color: Color(0xffbcbbc1),
            height: 0.3,
          ),
          SettingsItem(
            label: textLogout,
            content: SettingsNavigationIndicator(),
            onPress: () {
              logout(context);
            },
          ),
          Container(
            color: Color(0xffbcbbc1),
            height: 0.3,
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: PrimaryButton(
                    text: scanTickets,
                    onPress: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
