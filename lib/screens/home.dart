import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:foria/tabs/explore_events_tab.dart';
import 'package:foria/tabs/organizer_events_tab.dart';
import 'package:foria/utils/auth_utils.dart';
import 'package:foria/utils/size_config.dart';
import 'package:get_it/get_it.dart';

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
  List<TabItem> _allTabs = new List<TabItem>();

  bool _venueTabEnabled = false;

  String _titleApp;
  int _tab = 1;

  List<TabItem> get allTabs => List.unmodifiable(_allTabs);

  @override
  void initState() {

    _tabController = new PageController(initialPage: 1);
    venueAccessCheck();
    this._titleApp = _allTabs[1].title;

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  ///
  /// Adds venue tab is if user is logged in as a venue.
  ///
  void venueAccessCheck() {

    //Builds base set of tabs for all users.
    for (TabItem currentTab in baseTabItems) {
      _allTabs.add(currentTab);
    }

    final AuthUtils authUtils = GetIt.instance<AuthUtils>();

    if (authUtils.isVenue) {
      _venueTabEnabled = true;
      _allTabs.add(TabItem(
        title: 'Manage Events',
        icon: FontAwesomeIcons.qrcode,
        activeIcon: FontAwesomeIcons.qrcode,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {

    final List<Widget> tabContent = [
      new ExploreEventsTab(),
      new MyEventsTab(),
      new AccountTab()
    ];

    if (_venueTabEnabled) {
      tabContent.add(new OrganizerEventsTab());
    }

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
              children: tabContent
      ),
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
        items: _allTabs.map((tabItem) {
          return new BottomNavigationBarItem(
            title: new Text(tabItem.title),
            icon: new Icon(tabItem.icon),
            activeIcon: new Icon(tabItem.activeIcon),
          );
        }).toList(),
      )
          : new BottomNavigationBar(
        currentIndex: _tab,
        type: BottomNavigationBarType.fixed,
        onTap: onTap,
        backgroundColor: Colors.white,
        items: _allTabs.map((tabItem) {
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
      this._titleApp = _allTabs[tab].title;
    });
  }
}

class TabItem {

  const TabItem({this.title, this.icon, this.activeIcon});

  final String title;
  final IconData icon;
  final IconData activeIcon;
}

const List<TabItem> baseTabItems = const <TabItem>[
  const TabItem(
    title: 'Explore',
    icon: IconData(
      0xea4a,
      fontFamily: 'outline_material_icons',
    ),
    activeIcon: Icons.explore,
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
