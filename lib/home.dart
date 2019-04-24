import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import './tabs/tickets.dart' as _ticketsTab;
import './tabs/settings.dart' as _settingsTab;

class Home extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    return new Tabs();
  }
}

class FromRightToLeft<T> extends MaterialPageRoute<T> {
  FromRightToLeft({ WidgetBuilder builder, RouteSettings settings })
      : super(builder: builder, settings: settings);

  @override
  Widget buildTransitions(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {

    if (settings.isInitialRoute)
      return child;

    return new SlideTransition(
      child: new Container(
        decoration: new BoxDecoration(
            boxShadow: [
              new BoxShadow(
                color: Colors.black26,
                blurRadius: 25.0,
              )
            ]
        ),
        child: child,
      ),
      position: new Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      )
          .animate(
          new CurvedAnimation(
            parent: animation,
            curve: Curves.fastOutSlowIn,
          )
      ),
    );
  }
  @override Duration get transitionDuration => const Duration(milliseconds: 400);
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
  void dispose(){
    super.dispose();
    _tabController.dispose();
  }

  @override
  Widget build (BuildContext context) => new Scaffold(

    //App Bar
      appBar: new AppBar(
        title: new Text(
          _titleApp,
          style: new TextStyle(
            fontSize: Theme.of(context).platform == TargetPlatform.iOS ? 17.0 : 20.0,
          ),
        ),
        elevation: Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
      ),

      //Content of tabs
      body: new PageView(
        controller: _tabController,
        onPageChanged: onTabChanged,
        children: <Widget>[
          new _ticketsTab.Tickets(),
          new _settingsTab.Settings()
        ],
      ),

      //Tabs
      bottomNavigationBar: Theme.of(context).platform == TargetPlatform.iOS ?
      new CupertinoTabBar(
        activeColor: Colors.blueGrey,
        currentIndex: _tab,
        onTap: onTap,
        items: TabItems.map((TabItem) {
          return new BottomNavigationBarItem(
            title: new Text(TabItem.title),
            icon: new Icon(TabItem.icon),
          );
        }).toList(),
      ):
      new BottomNavigationBar(
        currentIndex: _tab,
        onTap: onTap,
        items: TabItems.map((TabItem) {
          return new BottomNavigationBarItem(
            title: new Text(TabItem.title),
            icon: new Icon(TabItem.icon),
          );
        }).toList(),
      ),

      //Drawer
      drawer: new Drawer(
          child: new ListView(
            children: <Widget>[
              new Container(
                height: 120.0,
                child: new DrawerHeader(
                  padding: new EdgeInsets.all(0.0),
                  decoration: new BoxDecoration(
                    color: new Color(0xFFECEFF1),
                  ),
                  child: new Center(
                    child: new FlutterLogo(
                      colors: Colors.blueGrey,
                      size: 54.0,
                    ),
                  ),
                ),
              ),
              new ListTile(
                  leading: new Icon(Icons.chat),
                  title: new Text('Support'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/support');
                  }
              ),
              new ListTile(
                  leading: new Icon(Icons.info),
                  title: new Text('About'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/about');
                  }
              ),
              new Divider(),
              new ListTile(
                  leading: new Icon(Icons.exit_to_app),
                  title: new Text('Sign Out'),
                  onTap: () {
                    Navigator.pop(context);
                  }
              ),
            ],
          )
      )
  );

  void onTap(int tab){
    _tabController.jumpToPage(tab);
  }

  void onTabChanged(int tab) {
    setState((){
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
  const TabItem({ this.title, this.icon });
  final String title;
  final IconData icon;
}

const List<TabItem> TabItems = const <TabItem>[
  const TabItem(title: 'Tickets', icon: Icons.home),
  const TabItem(title: 'Settings', icon: Icons.settings)
];