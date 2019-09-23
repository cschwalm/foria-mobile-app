


import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/providers/ticket_provider.dart';
import 'package:foria/utils/constants.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria/widgets/errors/image_unavailable.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';


///
/// Sets up the provider for the discover events tab and shows spinner when loading
///
class DiscoverEventsTab extends StatefulWidget {
  @override
  _DiscoverEventsTabState createState() => _DiscoverEventsTabState();
}

enum _LoadingState {

  INITIAL_LOAD,
  NETWORK_ERROR,
  EVENTS_LOADED,
  NO_EVENTS_AVAILABLE
}

class _DiscoverEventsTabState extends State<DiscoverEventsTab> {

  TicketProvider _ticketProvider;

  _LoadingState _currentState;

  @override
  void initState() {
    debugPrint('Home: Init state called');
    _ticketProvider = GetIt.instance<TicketProvider>();
    _currentState = _LoadingState.INITIAL_LOAD;
    super.initState();
  }


  ///
  /// Helper function that allows ticket loading to be blocked until finishing.
  ///
  Future<void> _loadEvents() async {

    TicketProvider ticketProvider = _ticketProvider;

    try {
      await ticketProvider.loadUserDataFromNetwork();
      setState(() {
        _currentState = _LoadingState.EVENTS_LOADED;
      });
      debugPrint('Discover events state set to $_currentState');
    } catch (e){
      setState(() {
        _currentState = _LoadingState.NETWORK_ERROR;
      });
      debugPrint('Discover events state set to $_currentState');
    }
  }

  Widget _noEvents (){
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: <Widget>[
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(noEventsAvailable,
                  style: Theme.of(context).textTheme.title,
                  textAlign: TextAlign.center,),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _error (){
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: <Widget>[
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(textOops,
                  style: Theme.of(context).textTheme.title,
                  textAlign: TextAlign.center,),
                sizedBoxH3,
                GestureDetector(
                  child: Text(tryAgain,
                    style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: constPrimaryColor),
                    textAlign: TextAlign.center,
                  ),
                  onTap: _loadEvents,
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (_currentState == _LoadingState.INITIAL_LOAD) {
      child = CupertinoActivityIndicator(radius: 15);
      _loadEvents();
    } else if (_currentState == _LoadingState.EVENTS_LOADED) {
      child = EventList();
    } else if (_currentState == _LoadingState.NO_EVENTS_AVAILABLE) {
      child = _noEvents();
    } else {
      child = _error();

    }

    return ChangeNotifierProvider.value(value: _ticketProvider, child: child);
  }
}

class EventList extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final eventData = Provider.of<TicketProvider>(context, listen: true);
    final Duration timezoneOffset = DateTime.now().timeZoneOffset;
    final Duration timeDiff = new Duration(hours: timezoneOffset.inHours, minutes: timezoneOffset.inMinutes % 60);

    return ListView.builder(
            itemCount: eventData.eventList.length,
            itemBuilder: (context, index) {
              DateTime serverStartTime = eventData.eventList[index].startTime;
              DateTime localStartTime = serverStartTime.add(timeDiff);
              EventAddress addr = eventData.eventList[index].address;


              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: GestureDetector(
                  key: Key(eventData.eventList[index].id),
                  onTap: () async {
                    if (await canLaunch('https://events-test.foriatickets.com/?eventId=52991c6d-7703-488d-93ae-1aacdd7c4291')) {
                      await launch('https://events-test.foriatickets.com/?eventId=52991c6d-7703-488d-93ae-1aacdd7c4291');
                    } else {
                      print("Failed to load FAQ URL."); ///
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        height: 150,
                        width: double.infinity,
                        child: eventData.eventList[index].imageUrl == null ? null :
                        CachedNetworkImage(
                          placeholder: (context, url) =>
                              CupertinoActivityIndicator(),
                          errorWidget: (context, url, error) {
                            return ImageUnavailable();
                          },
                          imageUrl: eventData.eventList[index].imageUrl,
                          imageBuilder: (context, imageProvider) =>
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(Radius.circular(2)),
                                  image: DecorationImage(
                                    image: imageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                        ),
                      ),
                      sizedBoxH3,
                      Text(
                        eventData.eventList[index].name,
                        style: Theme.of(context).textTheme.title,
                      ),
                      sizedBoxH3,
                      Text(
                        dateFormatDay.format(localStartTime),
                        style: Theme.of(context).textTheme.body2,
                      ),
                      sizedBoxH3,
                      Text(
                        addr.city+', '+addr.state,
                        style: Theme.of(context).textTheme.body2,
                      ),
                    ],
                  ),
                ),
              );
            });
  }
}

