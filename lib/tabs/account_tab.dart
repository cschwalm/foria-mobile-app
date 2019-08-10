import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/main.dart';
import 'package:foria/screens/venue_screen.dart';
import 'package:foria/utils/auth_utils.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria/widgets/primary_button.dart';

import '../widgets/contact_support.dart';
import '../widgets/settings_item.dart';

class AccountTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: settingsBackgroundColor,
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 20,
          ),
          SettingItemDivider(),
          SettingsItem(
            label: FAQ,
            content: SettingsNavigationIndicator(),
            onPress: () {
              Navigator.of(context).pushNamed(
                VenueScreen.routeName,
              );
            },
          ),
          SettingItemDivider(),
          SettingsItem(
            label: contactUs,
            content: SettingsNavigationIndicator(),
            onPress: () {
              contactSupport();
            },
          ),
          SettingItemDivider(),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: PrimaryButton(
                    text: textLogout,
                    onPress: () {
                      logout(context);
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
