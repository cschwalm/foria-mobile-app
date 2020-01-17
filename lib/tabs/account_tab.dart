import 'dart:developer';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/utils/auth_utils.dart';
import 'package:foria/utils/constants.dart';
import 'package:foria/utils/firebase_events.dart';
import 'package:foria/utils/message_stream.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria/widgets/primary_button.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/contact_support.dart';
import '../widgets/settings_item.dart';

///
/// Displays user account info and allows logout.
///
class AccountTab extends StatefulWidget {

  @override
  _AccountTabState createState() => _AccountTabState();
}

enum _LoadingState {
  NOT_READY, LOADED
}

class _AccountTabState extends State<AccountTab> with AutomaticKeepAliveClientMixin<AccountTab> {

  AuthUtils _authUtils;
  MessageStream _errorStream;
  _LoadingState _state = _LoadingState.NOT_READY;
  User _user;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {

    _authUtils = GetIt.instance<AuthUtils>();
    _errorStream = GetIt.instance<MessageStream>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    super.build(context);

    _errorStream.addListener((errorMessage) {
      Scaffold.of(context).showSnackBar(
          SnackBar(
            backgroundColor: snackbarColor,
            elevation: 0,
            content: FlatButton(
              child: Text(errorMessage.body),
              onPressed: () => Scaffold.of(context).hideCurrentSnackBar(),
            ),
          )
      );
    });

    //Populate user data after token has been loaded.
    _authUtils.user.then((user) {
      setState(() {
        _user = user;
        _state = _LoadingState.LOADED;
      });
    });

    Widget accountInfo;
    if (_state == _LoadingState.LOADED) {
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
                    _user.firstName + ' ' + _user.lastName,
                    style: Theme.of(context).textTheme.display1,
                  ),
                  SizedBox(height: 7),
                  Text(
                    _user.email,
                    style: Theme.of(context).textTheme.body1,
                  ),
                ],
              ),
            ),
          ),
        )
      ],);
    } else {
      accountInfo = SizedBox(height: 20);
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
                FirebaseAnalytics().logEvent(name: FAQ_VIEWED);
                await launch(FAQUrl);
              } else {
                log("Failed to load FAQ URL.", level: Level.WARNING.value);
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
