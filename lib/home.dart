import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import './tabs/my_passes.dart' as _myPassesTab;
import './tabs/account.dart' as _accountTab;

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Tabs();
  }
}

class FromRightToLeft<T> extends MaterialPageRoute<T> {
  FromRightToLeft({WidgetBuilder builder, RouteSettings settings})
      : super(builder: builder, settings: settings);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    if (settings.isInitialRoute) return child;

    return new SlideTransition(
      child: new Container(
        decoration: new BoxDecoration(boxShadow: [
          new BoxShadow(
            color: Colors.black26,
            blurRadius: 25.0,
          )
        ]),
        child: child,
      ),
      position: new Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(new CurvedAnimation(
        parent: animation,
        curve: Curves.fastOutSlowIn,
      )),
    );
  }

  @override
  Duration get transitionDuration => const Duration(milliseconds: 400);
}

class Tabs extends StatefulWidget {
  @override
  TabsState createState() => new TabsState();
}

class TabsState extends State<Tabs> {
  PageController _tabController;

  var _titleApp;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = new PageController();
    this._titleApp = TabItems[0].title;
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  @override
  Widget build(BuildContext context) => new Scaffold(
        //App Bar
        appBar: new AppBar(
          title: new Text(
            _titleApp,
            style: new TextStyle(
              fontSize: Theme.of(context).platform == TargetPlatform.iOS
                  ? 17.0
                  : 20.0,
            ),
          ),
          elevation:
              Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
        ),

        //Content of tabs
        body: new PageView(
          controller: _tabController,
          onPageChanged: onTabChanged,
          children: <Widget>[
            new _myPassesTab.MyPassesTab(),
            new _accountTab.AccountTab()
          ],
        ),

        //Tabs
        bottomNavigationBar: Theme.of(context).platform == TargetPlatform.iOS
            ? new CupertinoTabBar(
                activeColor: Theme.of(context).primaryColor,
                iconSize: 26,
                currentIndex: _tab,
                onTap: onTap,
                items: TabItems.map((TabItem) {
                  return new BottomNavigationBarItem(
                    title: new Text(TabItem.title),
                    icon: new Icon(TabItem.icon),
                    activeIcon: new Icon(TabItem.activeIcon),
                  );
                }).toList(),
              )
            : new BottomNavigationBar(
                currentIndex: _tab,
                onTap: onTap,
                items: TabItems.map((TabItem) {
                  return new BottomNavigationBarItem(
                    title: new Text(TabItem.title),
                    icon: new Icon(TabItem.icon),
                    activeIcon: new Icon(TabItem.activeIcon),
                  );
                }).toList(),
              ),
      );

  void onTap(int tab) {
    _tabController.jumpToPage(tab);
  }

  void onTabChanged(int tab) {
    setState(() {
      this._tab = tab;
    });

    switch (tab) {
      case 0:
        this._titleApp = TabItems[0].title;
        break;

      case 1:
        this._titleApp = TabItems[1].title;
        break;
    }
  }
}

class TabItem {
  const TabItem({this.title, this.icon, this.activeIcon});

  final String title;
  final IconData icon;
  final IconData activeIcon;
}

const List<TabItem> TabItems = const <TabItem>[
  const TabItem(
      title: 'My Passes',
      icon: IconData(0xe900,fontFamily: 'ticket',),
    activeIcon: IconData(0xe900,fontFamily: 'ticket',),
  ),
  const TabItem(
      title: 'Account',
      icon: FontAwesomeIcons.user,
    activeIcon: FontAwesomeIcons.solidUser,
  )
];
