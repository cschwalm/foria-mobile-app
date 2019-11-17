import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/providers/venue_provider.dart';
import 'package:foria/screens/attendee_list_screen.dart';
import 'package:foria/utils/constants.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria/widgets/discover_event_image.dart';
import 'package:foria/widgets/errors/error_try_again_column.dart';
import 'package:foria/widgets/no_events_column.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

///
/// Displays all the events an organizer has access to
///
class OrganizerEventsScreen extends StatefulWidget {

  static const routeName = '/organizer-events-screen';

  @override
  _OrganizerEventsScreenState createState() => _OrganizerEventsScreenState();
}
enum _LoadingState {

  INITIAL_LOAD,
  NETWORK_ERROR,
  EVENTS_LOADED,
  NO_EVENTS_AVAILABLE
}

class _OrganizerEventsScreenState extends State<OrganizerEventsScreen> with AutomaticKeepAliveClientMixin<OrganizerEventsScreen> {

  VenueProvider _venueProvider;
  _LoadingState _currentState;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    _venueProvider = GetIt.instance<VenueProvider>();
    _currentState = _LoadingState.INITIAL_LOAD;
    super.initState();
  }

  ///
  /// Fires network call to load and cache events.
  ///
  Future<void> _loadEvents() async {

    try {
      List<Event> events = await _venueProvider.getAllVenuesEvents();
      setState(() {
        if (events == null || events.isEmpty) {
          _currentState = _LoadingState.NO_EVENTS_AVAILABLE;
        } else {
          _currentState = _LoadingState.EVENTS_LOADED;
        }
      });
    } catch (e) {
      setState(() {
        _currentState = _LoadingState.NETWORK_ERROR;
      });
      debugPrint('getAllVenuesEvents network call failed. No events loaded.');
    }
  }

  @override
  Widget build(BuildContext context) {

    super.build(context);

    Widget child;
    if (_currentState == _LoadingState.INITIAL_LOAD) {
      child = Center(child: CupertinoActivityIndicator(radius: 15));
      _loadEvents();
    } else if (_currentState == _LoadingState.EVENTS_LOADED) {
      child = OrganizerEventList();
    } else if (_currentState == _LoadingState.NO_EVENTS_AVAILABLE) {
      child = NoEventsColumn();
    } else {
      child = ErrorTryAgainColumn(() => _loadEvents());
    }

    return ChangeNotifierProvider<VenueProvider>.value(
        value: _venueProvider,
        child: Scaffold(
          backgroundColor: settingsBackgroundColor,
          appBar: AppBar(
            title: Text(selectEvent),
            backgroundColor: Theme.of(context).primaryColorDark,
          ),
          body: child
        )
    );
  }
}

///
/// Creates a list view containing all the events.
///
class OrganizerEventList extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    final eventData = Provider.of<VenueProvider>(context, listen: true);
    final Duration timezoneOffset = DateTime.now().timeZoneOffset;
    final Duration timeDiff = new Duration(hours: timezoneOffset.inHours, minutes: timezoneOffset.inMinutes % 60);

    return ListView.builder(
        itemCount: eventData.venueEvents.length,
        itemBuilder: (context, index) {
          DateTime serverStartTime = eventData.venueEvents[index].startTime;
          DateTime localStartTime = serverStartTime.add(timeDiff);
          EventAddress addr = eventData.venueEvents[index].address;
          final String imageUrl = eventData.venueEvents[index].imageUrl;

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: GestureDetector(
              key: Key(eventData.venueEvents[index].id),
              onTap: () {
                Navigator.of(context).pushNamed(
                    AttendeeListScreen.routeName,
                  arguments: {
                    'eventId': eventData.venueEvents[index].id,
                  },
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    height: 150,
                    width: double.infinity,
                    child: DiscoverEventImage(imageUrl),
                  ),
                  sizedBoxH3,
                  Text(
                    eventData.venueEvents[index].name,
                    style: Theme.of(context).textTheme.title,
                  ),
                  sizedBoxH3,
                  Text(
                    dateFormatDay.format(localStartTime),
                    style: Theme.of(context).textTheme.body2,
                  ),
                  sizedBoxH3,
                  Text(
                    addr.city + ', ' + addr.state,
                    style: Theme.of(context).textTheme.body2,
                  ),
                ],
              ),
            ),
          );
        });
  }
}