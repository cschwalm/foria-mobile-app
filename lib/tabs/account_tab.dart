import 'package:flutter/material.dart';
import 'package:foria/screens/venue_screen.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria/utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:foria/widgets/primary_button.dart';

import '../widgets/contact_support.dart';
import '../widgets/settings_item.dart';

class AccountTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xfff0f0f0),
      child: Column(
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
            onPress: () {
              Navigator.of(context).pushNamed(
                VenueScreen.routeName,
              );
            },
          ),
          Container(
            color: Color(0xffbcbbc1),
            height: 0.3,
          ),
          SettingsItem(
            label: contactUs,
            content: SettingsNavigationIndicator(),
            onPress: () {
              contactSupport();
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
