import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/utils/auth_utils.dart';
import 'package:foria/utils/constants.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria/widgets/primary_button.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/contact_support.dart';
import '../widgets/settings_item.dart';

class AccountTab extends StatelessWidget {

  final AuthUtils _authUtils = new AuthUtils();

  final String _firstName = AuthUtils.user.firstName;
  final String _lastName = AuthUtils.user.lastName;
  final String _email = AuthUtils.user.email;

  @override
  Widget build(BuildContext context) {

    Widget accountInfo;
    if(_firstName == null || _lastName == null || _email == null){
      accountInfo = SizedBox(height: 20);
    } else {
      accountInfo = Row(children: <Widget>[
        Expanded(
          child: Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 35),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    _firstName+' '+_lastName,
                    style: Theme.of(context).textTheme.display1,
                  ),
                  SizedBox(height: 7),
                  Text(
                    _email,
                    style: Theme.of(context).textTheme.body1,
                  ),
                ],
              ),
            ),
          ),
        )
      ],);
    }

    return Container(
      color: settingsBackgroundColor,
      child: Column(
        children: <Widget>[
          accountInfo,
          MajorSettingItemDivider(),
          SettingsItem(
            label: FAQ,
            content: SettingsNavigationIndicator(),
            onPress: () async {
              if (await canLaunch(FAQUrl)) {
                await launch(FAQUrl);
              } else {
                print("Failed to load FAQ URL.");
              }
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
                      _authUtils.logout();
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
