import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/screens/organizer_events_screen.dart';
import 'package:foria/utils/auth_utils.dart';
import 'package:foria/utils/constants.dart';
import 'package:foria/widgets/contact_support.dart';
import 'package:foria/widgets/settings_item.dart';
import 'package:get_it/get_it.dart';

import '../utils/strings.dart';
import 'home.dart';

///
/// Organizer screen that provides buttons for Attendee Check-in, Logout, switch to fan screen, FAQ, Contact Us
///
class OrganizerHomeScreen extends StatelessWidget {
  static const routeName = '/organizer-screen';

  final AuthUtils _authUtils = GetIt.instance<AuthUtils>();

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
            label: switchToRegAccount,
            content: SettingsNavigationIndicator(),
            onPress: () {
              Navigator.of(context).pushReplacementNamed(Home.routeName);
            },
          ),
          MajorSettingItemDivider(),
          SettingsItem(
            label: textLogout,
            content: SettingsNavigationIndicator(),
            onPress: () {
              _authUtils.logout();
            },
          ),
          MajorSettingItemDivider(),
          SettingsItem(
            label: attendeeCheckIn,
            labelTextStyle: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold,color: Theme.of(context).primaryColor),
            content: SettingsNavigationIndicator(),
            onPress: () {
              Navigator.of(context).pushNamed(OrganizerEventsScreen.routeName);
            },
          ),
          SettingItemDivider(),
        ],
      ),
    );
  }
}
