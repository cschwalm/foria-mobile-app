import 'package:flutter/material.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria/utils/utils.dart';
import 'package:flutter/cupertino.dart';

import '../widgets/contact_support.dart';
import '../widgets/settings_item.dart';
import '../screens/selected_ticket_screen.dart';

class AccountTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        color: Color(0xfff0f0f0),
        child: Column(
          children: <Widget>[
            SizedBox(height: 20,),
            Container(
              color: Color(0xffbcbbc1),
              height: 0.3,
            ),
            SettingsItem(
              label: FAQ,
              content: SettingsNavigationIndicator(),
              onPress: () {
                Navigator.of(context).pushNamed(
                  SelectedTicketScreen.routeName,
                  arguments: null,
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
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(children: <Widget>[
                      Expanded(
                        child: CupertinoButton(
                          child: Text(
                            textLogout,
                            style: Theme.of(context).textTheme.button,
                          ),
                          color: Theme.of(context).primaryColor,
                          onPressed: () {
                            logout(context);
                          },
                        ),
                      ),
                    ],
                    ),
                  ),
                  SizedBox(height: 20,),
                ],
              ),
            ),

          ],
        ),
      );
}
