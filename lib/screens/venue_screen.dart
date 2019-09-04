import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/main.dart';
import 'package:foria/screens/ticket_scan_screen.dart';
import 'package:foria/utils/auth_utils.dart';
import 'package:foria/widgets/contact_support.dart';
import 'package:foria/widgets/primary_button.dart';
import 'package:foria/widgets/settings_item.dart';

import '../utils/strings.dart';

class VenueScreen extends StatelessWidget {
  static const routeName = '/venue-screen';

  final AuthUtils _authUtils = new AuthUtils();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: settingsBackgroundColor,
      appBar: AppBar(
        title: Text(venueAccount),
        backgroundColor: Theme.of(context).primaryColorDark,
      ),
      body: Column(
        children: <Widget>[
          SizedBox(height: 10,),
          SettingItemDivider(),
          SettingsItem(
            label: FAQ,
            content: SettingsNavigationIndicator(),
            onPress: () {},
          ),
          SettingItemDivider(),
          SettingsItem(
            label: contactUs,
            content: SettingsNavigationIndicator(),
            onPress: () {
              contactSupport();
            },
          ),
          MajorSettingItemDivider(),
          SettingsItem(
            label: textLogout,
            labelTextStyle: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold,color: Theme.of(context).primaryColor),
            content: SettingsNavigationIndicator(),
            onPress: () {
              _authUtils.logout();
            },
          ),
          SettingItemDivider(),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 40),
                  child: PrimaryButton(
                    text: scanTickets,
                    onPress: () {
                      Navigator.pushNamed(context, TicketScanScreen.routeName);
                    },
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
