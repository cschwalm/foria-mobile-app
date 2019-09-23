import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:foria/tabs/discover_events_tab.dart';
import 'package:foria/utils/size_config.dart';

import '../tabs/account_tab.dart';
import '../tabs/my_events_tab.dart';

class Home extends StatelessWidget {

  static const routeName = '/home';

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

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
  MyEventsTab _myPassesTab;
  AccountTab _accountTab;
  DiscoverEventsTab _discoverEventsTab;

  String _titleApp;
  int _tab = 1;

  @override
  void initState() {

    _tabController = new PageController(initialPage: 1);
    _myPassesTab = new MyEventsTab();
    _accountTab = new AccountTab();
    _discoverEventsTab = new DiscoverEventsTab();

    this._titleApp = TabItems[1].title;

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return new Scaffold(
      //App Bar
      appBar: new AppBar(
        title: new Text(
          _titleApp,
          style: new TextStyle(
            fontSize: Theme
                .of(context)
                .platform == TargetPlatform.iOS
                ? 18.0
                : 20.0,
          ),
        ),
        elevation:
        Theme
            .of(context)
            .platform == TargetPlatform.iOS ? 0.0 : 4.0,
      ),

      //Content of tabs
      body: PageView(
              controller: _tabController,
              onPageChanged: onTabChanged,
              children: <Widget>[
                _discoverEventsTab,
                _myPassesTab,
                _accountTab,
              ]),
      bottomNavigationBar: Theme
          .of(context)
          .platform == TargetPlatform.iOS
          ? new CupertinoTabBar(
        activeColor: Theme
            .of(context)
            .primaryColor,
        iconSize: 26,
        currentIndex: _tab,
        onTap: onTap,
        backgroundColor: Colors.white,
        items: TabItems.map((tabItem) {
          return new BottomNavigationBarItem(
            title: new Text(tabItem.title),
            icon: new Icon(tabItem.icon),
            activeIcon: new Icon(tabItem.activeIcon),
          );
        }).toList(),
      )
          : new BottomNavigationBar(
        currentIndex: _tab,
        onTap: onTap,
        backgroundColor: Colors.white,
        items: TabItems.map((tabItem) {
          return new BottomNavigationBarItem(
            title: new Text(tabItem.title),
            icon: new Icon(tabItem.icon),
            activeIcon: new Icon(tabItem.activeIcon),
          );
        }).toList(),
      ),
    );
  }

  void onTap(int tab) {

    setState(() {
      _tabController.jumpToPage(tab);
    });
  }

  void onTabChanged(int tab) {

    setState(() {
      this._tab = tab;

      switch (tab) {
        case 0:
          this._titleApp = TabItems[0].title;
          break;

        case 1:
          this._titleApp = TabItems[1].title;
          break;

        case 2:
          this._titleApp = TabItems[2].title;
          break;
      }
    });
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
    title: 'Home',
    icon: IconData(
      0xead0,
      fontFamily: 'outline_material_icons',
    ),
    activeIcon: Icons.home,
  ),
  const TabItem(
    title: 'My Passes',
    icon: IconData(
      0xe900,
      fontFamily: 'ticket',
    ),
    activeIcon: IconData(
      0xe900,
      fontFamily: 'ticket',
    ),
  ),
  const TabItem(
    title: 'Account',
    icon: FontAwesomeIcons.user,
    activeIcon: FontAwesomeIcons.solidUser,
  )
];
